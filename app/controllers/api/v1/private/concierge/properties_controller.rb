# frozen_string_literal: true

# GET /api/v1/private/concierge/properties
#
# Properties the current user operates as concierge. Empty for anyone else.
class Api::V1::Private::Concierge::PropertiesController < Api::V1::Private::BaseController
  include Api::ConciergePropertyContext

  def index
    properties = ResidentialProperty.where(id: concierge_property_ids).order(:name)

    render json: { data: properties.map { |property| { id: property.id, name: property.name } } }, status: :ok
  end
end
