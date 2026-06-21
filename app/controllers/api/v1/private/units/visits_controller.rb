# frozen_string_literal: true

# POST /api/v1/private/units/:unit_id/visits
#
# Private authenticated endpoint for resident visit registration.
# Distinct from the administrative Inertia visit flow.
#
# This endpoint creates visits exclusively in `authorized` status.
# Only residents with an active unit relationship and `authorize_visits`
# capability may use it. A `pending` visit flow requires a separate contract.
#
# Accepted payload (client-supplied):
#   unit_id       – path param; resolved tenant-safely from current organization
#   visitor.name  – visitor full name
#   visitor.document – visitor identity document
#   visitor.phone – visitor phone number
#   scheduled_at  – ISO 8601 datetime
#
# NOT accepted from client (resolved in backend):
#   organization_id, residential_property_id, property_section_id,
#   host_person_id, created_by_id, authorized_by_id, status
class Api::V1::Private::Units::VisitsController < Api::V1::Private::BaseController
  def create
    # Authorization, visitor resolution and visit persistence are implemented
    # in subsequent sections (2.x – 4.x). This action raises NotImplementedError
    # until those tasks are complete so callers receive a clear signal.
    raise NotImplementedError, "Resident visit creation not yet implemented"
  end

  private

  def visit_params
    params.require(:visit).permit(
      :scheduled_at,
      visitor: %i[name document phone]
    )
  end
end
