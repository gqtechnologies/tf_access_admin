class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  set_current_tenant_through_filter
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  before_action :set_current_organization
  before_action :set_locale
  # Share data with all Inertia responses, this is used to pass the locale and translations to the client
  inertia_share app: -> {
    {
      locale: I18n.locale,
      available_locales: I18n.available_locales.map(&:to_s),
      translations: frontend_translations(I18n.locale)
    }
  }

  protected

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  private

  def set_current_organization
    subdomain = subdomain_from_request

    if subdomain.blank?
      if request.path == "/"
        redirect_to(home_path) and return
      end

      return if allow_request_without_organization?

      redirect_to(home_path) and return
    end

    organization = Organization.find_by(subdomain: subdomain)
    if organization
      set_current_tenant(organization)
    else
      # Evita bucle: el subdominio no existe; vuelve al host público (p. ej. abc.localhost → localhost)
      redirect_to home_url(public_home_url_options), allow_other_host: true and return
    end
  end

  # Rutas que deben responder sin subdominio de organización (auth, health, assets internos).
  def allow_request_without_organization?
    path = request.path

    # path.start_with?("/users") || # Devise (sessions, passwords, confirmations)
      path.start_with?("/rails/") || # ActiveStorage, etc.
      path.start_with?("/assets/") ||
      path.start_with?("/vite-dev/") ||
      path == home_path
      # path == "/up" ||
      # path.start_with?("#{home_path}/") ||
      # path.start_with?("/sidekiq")
  end

  def public_home_url_options
    {
      host: host_without_organization_subdomain,
      port: (request.port if request.port != request.standard_port),
      protocol: request.protocol.delete_suffix("://")
    }.compact
  end

  def host_without_organization_subdomain
    sub = subdomain_from_request
    return request.host if sub.blank?

    stripped = request.host.sub(/\A#{Regexp.escape(sub)}\./, "")
    stripped.presence || request.host
  end

  def subdomain_from_request
    host = request.host
    if Rails.env.development? && host.end_with?(".localhost")
      host.remove(".localhost")
    else
      request.subdomain.presence
    end
  end

  def user_not_authorized
    redirect_back_or_to(root_path)
  end

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
