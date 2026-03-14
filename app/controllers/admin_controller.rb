# frozen_string_literal: true

class AdminController < InertiaController
  before_action :authenticate_user!
  before_action :set_locale

    inertia_share auth: -> {
      if user_signed_in?
        { user: current_user.as_json(only: [:id, :email, :language]) }
      else
        {}
      end
    }
    # Share data with all Inertia responses, this is used to pass the locale and translations to the client
    inertia_share app: -> {
      {
        locale: current_user.language.presence || I18n.locale.to_s,
        available_locales: I18n.available_locales.map(&:to_s),
        translations: frontend_translations(current_user.language.presence || I18n.locale)
      }
    }

  private

  # Set the locale for the user
  def set_locale
    I18n.locale =
      params[:locale].presence ||
      session[:locale].presence ||
      I18n.default_locale
  end

  # Get the translations for the frontend
  def frontend_translations(locale)
    I18n.t("frontend", locale: locale, default: {})
  end
  
end