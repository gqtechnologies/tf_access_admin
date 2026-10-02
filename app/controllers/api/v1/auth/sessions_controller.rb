# frozen_string_literal: true

class Api::V1::Auth::SessionsController < Api::V1::BaseController
  include Api::JwtSessionResponse

  skip_before_action :set_current_organization, only: [ :create ]

  before_action :authenticate_user!, only: [ :destroy ]
  before_action :ensure_destroy_tenant_access!, only: [ :destroy ]

  def create
    organization = get_organization_from_subdomain(api_subdomain_from_request)
    return render json: { error: I18n.t("api.errors.unauthorized_tenant") }, status: :unauthorized if organization.blank?

    user = ActsAsTenant.without_tenant do
      User.find_for_authentication(
        email: params[:email],
        organization_id: organization.id
      )
    end

    unless user&.valid_password?(params[:password])
      return render json: { error: I18n.t("api.errors.invalid_credentials") }, status: :unauthorized
    end

    if user.respond_to?(:confirmed?) && !user.confirmed?
      return render json: { error: I18n.t("api.errors.unconfirmed_account") }, status: :unauthorized
    end

    if user.deactivated_at.present?
      return render json: { error: I18n.t("api.errors.account_deactivated") }, status: :unauthorized
    end

    render_jwt_session(user, organization)
  end

  def destroy
    sign_out(current_user)
    head :no_content
  end

  private

  def ensure_destroy_tenant_access!
    return if current_user.super_admin?

    return if current_user.member_of_tenant?(ActsAsTenant.current_tenant)

    render json: { error: I18n.t("api.errors.forbidden") }, status: :forbidden
    nil
  end
end
