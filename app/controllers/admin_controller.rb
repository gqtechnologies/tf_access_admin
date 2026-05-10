# frozen_string_literal: true

class AdminController < InertiaController
  before_action :authenticate_user!
  before_action :set_locale
  # Usar `if:` en lugar de `only:` para no exigir la acción `index` en hijos sin esa acción
  # (p. ej. Devise::SessionsController), con raise_on_missing_callback_actions en Rails 7.1+.
  before_action :set_filters, if: -> { action_name == "index" }

  inertia_share auth: -> {
    if user_signed_in?
      { user: Admin::UserSerializer.new(current_user).as_json, features: current_user.features }
    else
      {}
    end
  }
  # Share data with all Inertia responses, this is used to pass the locale and translations to the client
  inertia_share app: -> {
    effective_locale = current_user&.language.presence || I18n.locale.to_s
    {
      locale: effective_locale,
      available_locales: I18n.available_locales.map(&:to_s),
      translations: frontend_translations(effective_locale)
    }
  }

  private

  # Set the locale for the user
  def set_locale
    I18n.locale =
      current_user&.language.presence ||
      params[:locale].presence ||
      session[:locale].presence ||
      I18n.default_locale
  end

  # Get the translations for the frontend
  def frontend_translations(locale)
    I18n.t("frontend", locale: locale, default: {})
  end

  def set_filters
    @filters = {
        page: params[:page] || 1,
        per_page: params[:per_page] || 10
    }
  end
end
