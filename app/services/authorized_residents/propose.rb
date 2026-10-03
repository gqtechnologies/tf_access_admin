# frozen_string_literal: true

module AuthorizedResidents
  # A resident proposes someone who doesn't live in the unit (a nanny, a driver,
  # a relative) to be let in without an invitation and, optionally, to pick up
  # the unit's parcels. The request stays pending until the administration
  # approves it. Only occupants who may authorize visits and owners propose.
  class Propose
    class NotAllowed < StandardError; end
    class AlreadyListed < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def self.can_propose?(person:, unit:)
      return false if person.blank? || unit.blank?

      relationships = Authorization::ActiveRelationships
      relationships.active_occupancies_of_unit(unit).where(person_id: person.id, can_authorize_visits: true).exists? ||
        relationships.active_ownerships_of_unit(unit).where(person_id: person.id).exists?
    end

    def initialize(unit:, proposer:, person_params:, attributes: {})
      @unit = unit
      @proposer = proposer
      @person_params = person_params.to_h.symbolize_keys.slice(:name, :email, :document, :phone)
      @attributes = attributes.to_h.symbolize_keys.slice(:relationship_type, :ends_at, :can_withdraw_parcels, :notes)
    end

    def call
      raise NotAllowed unless self.class.can_propose?(person: @proposer, unit: @unit)

      ActiveRecord::Base.transaction do
        person = Residents::ResolveVisitorPerson.call(organization: @unit.organization, visitor_params: @person_params)
        raise AlreadyListed if @unit.authorized_residents.open_requests.exists?(person_id: person.id)

        AuthorizedResident.create!(
          organization: @unit.organization,
          unit: @unit,
          person: person,
          authorized_by_person: @proposer,
          status: AuthorizedResidentStatuses::PENDING,
          starts_at: Time.zone.now,
          ends_at: parse_end(@attributes[:ends_at]),
          relationship_type: @attributes[:relationship_type].presence || RelationshipTypes::OTHER,
          can_withdraw_parcels: ActiveModel::Type::Boolean.new.cast(@attributes[:can_withdraw_parcels]) || false,
          notes: @attributes[:notes].to_s.strip.presence
        )
      end
    end

    private

    # An end date means "valid through that day" in the property's zone.
    def parse_end(value)
      return nil if value.blank?

      zone = ActiveSupport::TimeZone[@unit.residential_property.timezone.to_s] || Time.zone
      zone.parse(value.to_s)&.end_of_day
    end
  end
end
