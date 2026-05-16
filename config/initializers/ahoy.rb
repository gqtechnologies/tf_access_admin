# frozen_string_literal: true

class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data = data.dup
    inject_organization_id!(data)
    super
  end

  def track_event(data)
    data = data.dup
    inject_organization_id!(data)
    super
  end

  private

  def inject_organization_id!(data)
    org_id = Current.organization&.id || ActsAsTenant.current_tenant&.id
    data[:organization_id] = org_id if org_id.present?
  end
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false
