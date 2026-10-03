# frozen_string_literal: true

# GET /api/v1/private/concierge/authorized_people?property_id=&q=
#
# The approved, currently valid authorized people of an operated property, so
# the front desk can let them in without an invitation. +q+ matches the name
# or, exactly, the document.
class Api::V1::Private::Concierge::AuthorizedPeopleController < Api::V1::Private::BaseController
  include Api::ConciergePropertyContext

  LIMIT = 50

  before_action :load_property!

  def index
    people = AuthorizedResident.currently_valid
                               .joins(:unit, :person)
                               .where(units: { residential_property_id: @property.id })
                               .includes(:unit, person: :user)
                               .order("people.display_name")
    people = search(people)

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(
        people.limit(LIMIT), each_serializer: Api::Private::AuthorizedPersonSerializer
      ).as_json
    }, status: :ok
  end

  private

  def search(scope)
    query = params[:q].to_s.strip
    return scope if query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    scope.where("people.display_name ILIKE :q OR people.document_number_digest = :digest OR units.identifier ILIKE :q",
                q: pattern, digest: Person.document_digest(query))
  end
end
