# frozen_string_literal: true

class Api::V1::Private::BaseController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :ensure_current_user_belongs_to_tenant!

  private

  def ensure_current_user_belongs_to_tenant!
    return if current_user.blank? || ActsAsTenant.current_tenant.blank?

    return if current_user.super_admin?

    return if current_user.organization_id == ActsAsTenant.current_tenant.id

    render json: { error: I18n.t("api.errors.forbidden") }, status: :forbidden
    return
  end

  def pundit_user
    current_user
  end
end
