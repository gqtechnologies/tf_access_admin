# frozen_string_literal: true

# Resolves the residential properties the current user operates as concierge
# (view_authorized_visits) and pins a request to one of them.
module Api::ConciergePropertyContext
  extend ActiveSupport::Concern

  private

  def concierge_property_ids
    @concierge_property_ids ||= Authorization::Resolver
      .new(user: current_user, organization: ActsAsTenant.current_tenant)
      .profile
      .property_capabilities
      .select { |_, caps| caps.include?(Authorization::Capabilities::VIEW_AUTHORIZED_VISITS) }
      .keys
  end

  # Properties where the user may register parcel arrivals and withdrawals.
  # Organization-wide holders of manage_parcels operate every property.
  def parcel_property_ids
    @parcel_property_ids ||= begin
      resolver = Authorization::Resolver.new(user: current_user, organization: ActsAsTenant.current_tenant)

      if resolver.profile.organization_capabilities.include?(Authorization::Capabilities::MANAGE_PARCELS)
        ResidentialProperty.pluck(:id)
      else
        resolver.profile.property_capabilities
                .select { |_, caps| caps.include?(Authorization::Capabilities::MANAGE_PARCELS) }
                .keys
      end
    end
  end

  def load_parcel_property!
    property_id = params[:property_id].to_s
    @property = ResidentialProperty.find_by(id: property_id) if parcel_property_ids.map(&:to_s).include?(property_id)
    return if @property

    render json: { error: I18n.t("api.concierge.property_forbidden") }, status: :forbidden
  end

  # Missing property_id and a property outside the assignment are both 403:
  # the caller must always name a property it operates.
  def load_property!
    property_id = params[:property_id].to_s
    @property = ResidentialProperty.find_by(id: property_id) if concierge_property_ids.include?(property_id)
    return if @property

    render json: { error: I18n.t("api.concierge.property_forbidden") }, status: :forbidden
  end
end
