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

  # Missing property_id and a property outside the assignment are both 403:
  # the caller must always name a property it operates.
  def load_property!
    property_id = params[:property_id].to_s
    @property = ResidentialProperty.find_by(id: property_id) if concierge_property_ids.include?(property_id)
    return if @property

    render json: { error: I18n.t("api.concierge.property_forbidden") }, status: :forbidden
  end
end
