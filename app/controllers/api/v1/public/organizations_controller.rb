# frozen_string_literal: true

class Api::V1::Public::OrganizationsController < Api::V1::BaseController
  before_action :get_organization

  def index
    render_resource(@organization, serializer: Api::V1::Public::OrganizationSerializer)
  end

  private

  def get_organization
    @organization = get_organization_from_subdomain(api_subdomain_from_request)
    not_found if @organization.blank?
  end
end
