# frozen_string_literal: true

# GET  /api/v1/private/units/:unit_id/authorized_people
# POST /api/v1/private/units/:unit_id/authorized_people
# POST /api/v1/private/units/:unit_id/authorized_people/:id/withdraw
#
# People a unit authorizes to come in without an invitation (and optionally
# pick up parcels). Listing needs an active relationship with the unit;
# proposing and withdrawing need to be an occupant who may authorize visits or
# an owner. Proposals wait for the administration's approval.
class Api::V1::Private::Units::AuthorizedPeopleController < Api::V1::Private::BaseController
  before_action :load_unit

  def index
    people = @unit.authorized_residents
                  .where(status: [ AuthorizedResidentStatuses::PENDING, AuthorizedResidentStatuses::ACTIVE ])
                  .where("authorized_residents.ends_at IS NULL OR authorized_residents.ends_at >= ?", Time.zone.now)
                  .includes(:unit, person: :user)
                  .order(:created_at)

    render json: {
      data: serialize(people),
      can_propose: AuthorizedResidents::Propose.can_propose?(person: person, unit: @unit),
      relationship_types: RelationshipTypes::ALL
    }, status: :ok
  end

  def create
    record = AuthorizedResidents::Propose.call(
      unit: @unit,
      proposer: person,
      person_params: params.require(:person).permit(:name, :email, :document, :phone),
      attributes: params.fetch(:authorization, {}).permit(:relationship_type, :ends_at, :can_withdraw_parcels, :notes)
    )

    render json: { data: serialize(record) }, status: :created
  rescue AuthorizedResidents::Propose::NotAllowed
    render json: { error: I18n.t("api.authorized_people.not_allowed") }, status: :forbidden
  rescue AuthorizedResidents::Propose::AlreadyListed
    render json: { error: I18n.t("api.authorized_people.already_listed") }, status: :unprocessable_entity
  rescue Visits::ResolveVisitorPerson::IdentityConflict
    render json: { error: I18n.t("api.visits.identity_conflict") }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    message = e.respond_to?(:record) ? e.record.errors.full_messages.to_sentence : I18n.t("api.authorized_people.invalid_person")
    render json: { error: message }, status: :unprocessable_entity
  end

  def withdraw
    record = @unit.authorized_residents.find(params[:id])
    AuthorizedResidents::Withdraw.call(authorized_resident: record, person: person)

    render json: { data: serialize(record) }, status: :ok
  rescue AuthorizedResidents::Withdraw::NotAllowed
    render json: { error: I18n.t("api.authorized_people.not_allowed") }, status: :forbidden
  rescue AuthorizedResidents::Withdraw::NotOpen
    render json: { error: I18n.t("api.authorized_people.not_open") }, status: :unprocessable_entity
  end

  private

  def person
    @person ||= current_user.person_for(ActsAsTenant.current_tenant)
  end

  def load_unit
    @unit = Unit.with_active_relationship_for(person, ActsAsTenant.current_tenant).find(params[:unit_id])
  end

  def serialize(resource)
    options = {}
    options[resource.respond_to?(:each) ? :each_serializer : :serializer] = Api::Private::AuthorizedPersonSerializer

    ActiveModelSerializers::SerializableResource.new(resource, **options).as_json
  end
end
