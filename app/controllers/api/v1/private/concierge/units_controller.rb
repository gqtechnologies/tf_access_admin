# frozen_string_literal: true

# GET /api/v1/private/concierge/units?property_id=&q=
#
# Unit picker for front-desk registration: units of one property where the
# actor holds manage_parcels, optionally filtered by identifier or name.
class Api::V1::Private::Concierge::UnitsController < Api::V1::Private::BaseController
  include Api::ConciergePropertyContext

  LIMIT = 50

  before_action :load_parcel_property!

  def index
    units = @property.units.order(:identifier).limit(LIMIT)

    query = params[:q].to_s.strip
    if query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      units = units.where("units.identifier ILIKE :q OR units.display_name ILIKE :q", q: pattern)
    end

    render json: {
      data: units.map { |unit| { id: unit.id, name: unit.display_name.presence || unit.identifier } }
    }, status: :ok
  end
end
