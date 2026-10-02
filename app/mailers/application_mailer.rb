class ApplicationMailer < ActionMailer::Base
  default from: ENV["MAILGUN_FROM_ADDRESS"]
  layout "mailer"
  around_action :apply_mail_locale
  before_action :attach_banner_inline

  private

  def attach_banner_inline
    attachments.inline["banner.png"] = File.read(Rails.root.join("app/assets/images/mailer/banner.png"))
  end

  def apply_mail_locale(&block)
    locale =
      params[:locale].presence ||
      params[:user]&.language.presence ||
      (params[:user_id] && User.find_by(id: params[:user_id])&.language.presence) ||
      I18n.default_locale

    I18n.with_locale(locale, &block)
  end

  public

  def tenant_url_options_for(resource)
    mailer_defaults = Rails.application.config.action_mailer.default_url_options || {}
    base_host = mailer_defaults[:host].presence || "localhost"
    base_port = mailer_defaults[:port]
    protocol = Rails.env.production? ? "https" : "http"

    # A User belongs to several organizations, so it has no `organization`:
    # Devise mails (password reset) fall back to the tenant they were sent under.
    organization = resource.organization if resource.respond_to?(:organization)
    organization ||= ActsAsTenant.current_tenant
    subdomain = organization&.subdomain

    host = subdomain.present? ? "#{subdomain}.#{base_host}" : base_host

    opts = { host: host, protocol: protocol }
    opts[:port] = base_port if base_port.present?
    opts
  end
end
