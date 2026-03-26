class HomeController < ApplicationController
  def index
    organization = ActsAsTenant.current_tenant
    props = {}
    if organization
      props[:organization] = Admin::OrganizationSerializer.new(organization).as_json
    end
    render inertia: "home/index", props: props
  end
end
