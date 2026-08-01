module RequestSubdomain
  extend ActiveSupport::Concern

  def subdomain_from_request
    host = request.host
    if Rails.env.development? && host.end_with?(".localhost")
      host.remove(".localhost")
    else
      request.subdomains.first.presence
    end
  end

  def api_subdomain_from_request
    request.headers["X-Tenant-Subdomain"].presence || subdomain_from_request
  end

  def get_organization_from_subdomain(subdomain)
    Organization.find_by(subdomain: subdomain)
  end
end
