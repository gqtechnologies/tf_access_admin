# frozen_string_literal: true

# Resolves the properties where the current user holds a property-scoped
# management capability (all of them for an organization-wide holder) and
# pins an admin page to one via ?property_id=, defaulting to the first.
module ManagedPropertyContext
  extend ActiveSupport::Concern

  private

  def managed_properties_for(capability)
    @managed_properties ||= {}
    @managed_properties[capability] ||= begin
      profile = Authorization::Resolver.new(user: current_user, organization: Current.organization).profile

      if profile.organization_capabilities.include?(capability)
        ResidentialProperty.order(:name).to_a
      else
        ids = profile.property_capabilities.select { |_, caps| caps.include?(capability) }.keys
        ResidentialProperty.where(id: ids).order(:name).to_a
      end
    end
  end

  def active_managed_property(capability)
    properties = managed_properties_for(capability)
    properties.find { |property| property.id.to_s == params[:property_id].to_s } || properties.first
  end

  def property_summary(property)
    property && { id: property.id, name: property.name }
  end
end
