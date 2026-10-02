# frozen_string_literal: true

# POST /api/v1/auth/password — requests the Devise password reset email.
#
# The tenant comes from the subdomain or X-Tenant-Subdomain, as in login. The
# response is the same 202 whether or not an email went out, so the endpoint
# never reveals which emails are registered. Only confirmed, active members of
# the tenant get the email; the password itself is changed on the web page the
# email links to.
class Api::V1::Auth::PasswordsController < Api::V1::BaseController
  skip_before_action :set_current_organization

  rate_limit to: 5, within: 15.minutes, only: :create,
             with: -> { render_too_many_requests }

  def create
    organization = resolve_organization
    return unauthorized_tenant if organization.blank?

    # Devise stores emails downcased (case_insensitive_keys); find_for_authentication matches exactly.
    email = params[:email].to_s.strip.downcase
    return render json: { error: I18n.t("api.errors.email_required") }, status: :unprocessable_entity if email.blank?

    user = ActsAsTenant.without_tenant do
      User.find_for_authentication(email: email, organization_id: organization.id)
    end

    if eligible?(user)
      # deliver_now inside the tenant: the mail template builds the link with it.
      ActsAsTenant.with_tenant(organization) { user.send_reset_password_instructions }
    end

    render json: { data: { status: "requested" } }, status: :accepted
  end

  private

  def eligible?(user)
    return false if user.nil? || user.deactivated_at.present?

    !user.respond_to?(:confirmed?) || user.confirmed?
  end

  def render_too_many_requests
    response.set_header("Retry-After", 15.minutes.to_i.to_s)
    render json: { error: I18n.t("api.errors.too_many_requests") }, status: :too_many_requests
  end
end
