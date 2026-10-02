# frozen_string_literal: true

# POST /api/v1/auth/social — sign in, or sign up, with an Apple or Google
# identity token obtained by the mobile app.
#
#   provider  – "apple" | "google"
#   id_token  – the provider's identity token (JWT)
#   name, dni – only needed the first time, to create the account
#
# The tenant comes from the subdomain or X-Tenant-Subdomain, as in login. A
# verified email that already has an account in the organization signs in to
# it; an unknown one becomes a new visitor account. When the account has to be
# created and name/dni are missing the answer is 422 with
# code: "profile_required" and the list of missing fields, and the app retries
# with the same token once the user has filled them in.
class Api::V1::Auth::SocialSessionsController < Api::V1::BaseController
  include Api::JwtSessionResponse

  skip_before_action :set_current_organization

  rate_limit to: 10, within: 15.minutes, only: :create,
             with: -> { render_too_many_requests }

  def create
    organization = resolve_organization
    return unauthorized_tenant if organization.blank?

    claims = SocialAuth::TokenVerifier.call(provider: params[:provider], id_token: params[:id_token])
    result = Accounts::SocialSignIn.call(
      organization: organization,
      claims: claims,
      name: params[:name],
      dni: params[:dni],
      language: params[:language]
    )

    render_jwt_session(result.user, organization, created: result.created)
  rescue SocialAuth::TokenVerifier::InvalidToken
    render json: { error: I18n.t("api.social.invalid_token") }, status: :unauthorized
  rescue SocialAuth::TokenVerifier::NotConfigured
    render json: { error: I18n.t("api.social.not_configured") }, status: :service_unavailable
  rescue Accounts::SocialSignIn::EmailRequired
    render json: { error: I18n.t("api.social.email_required") }, status: :unprocessable_entity
  rescue Accounts::SocialSignIn::Deactivated
    render json: { error: I18n.t("api.errors.account_deactivated") }, status: :unauthorized
  rescue Accounts::SocialSignIn::ProfileRequired => e
    render json: {
      error: I18n.t("api.social.profile_required"),
      code: "profile_required",
      missing: e.missing,
      suggested_name: claims&.name
    }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue Accounts::LinkUserToPerson::Conflict
    render json: { error: I18n.t("api.social.invalid_token") }, status: :unprocessable_entity
  end

  private

  def render_too_many_requests
    response.set_header("Retry-After", 15.minutes.to_i.to_s)
    render json: { error: I18n.t("api.errors.too_many_requests") }, status: :too_many_requests
  end
end
