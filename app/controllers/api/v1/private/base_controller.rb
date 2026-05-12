# frozen_string_literal: true

class Api::V1::Private::BaseController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :ensure_current_user_belongs_to_tenant!

  private

  def ensure_current_user_belongs_to_tenant!
    return if current_user.blank? || ActsAsTenant.current_tenant.blank?

    return if current_user.super_admin?

    return if current_user.member_of_tenant?(ActsAsTenant.current_tenant)

    render json: { error: I18n.t("api.errors.forbidden") }, status: :forbidden
    nil
  end

  def pundit_user
    current_user
  end
end
