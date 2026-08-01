# frozen_string_literal: true

# GET /api/v1/mobile/units
#
# Lists the authenticated user's units, across every organization they belong
# to, where they hold both create_visits and authorize_visits capability.
class Api::V1::Mobile::UnitsController < Api::V1::Mobile::BaseController
  def index
    entries = Residents::EligibleUnits.call(user: current_user)

    render json: {
      data: entries.map do |entry|
        {
          id: entry.unit.id,
          name: entry.unit.display_name,
          organization: {
            id: entry.organization.id,
            name: entry.organization.name
          }
        }
      end
    }, status: :ok
  end
end
