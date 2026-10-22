# frozen_string_literal: true

class Api::V1::Private::BaseController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :reject_deactivated_user!
  before_action :ensure_current_user_belongs_to_tenant!
  around_action :use_user_locale

  private

  # Error messages follow the signed-in user's language. An around_action, so
  # the locale never leaks into the next request served by the same thread.
  def use_user_locale(&action)
    locale = current_user&.language.presence_in(I18n.available_locales.map(&:to_s))
    I18n.with_locale(locale || I18n.locale, &action)
  end

  # A token issued before the account was deactivated (or deleted, which
  # deactivates it) stops working at once instead of at its expiry.
  def reject_deactivated_user!
    return if current_user.blank? || current_user.deactivated_at.blank?

    render json: { error: I18n.t("api.errors.account_deactivated") }, status: :unauthorized
  end

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
