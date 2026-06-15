# frozen_string_literal: true

# Derives contextual domain roles for a +Person+ from active relationships.
#
# Staff contextual roles (+concierge+, +property_admin+, +cleaning_staff+) will
# be derived from active +StaffAssignment+ rows (+person_id+, +residential_property_id+,
# +staff_type+) when staff is wired operationally; see +StaffAssignment+.
module People
  class ContextualRoles
    OWNER = "owner"
    RESIDENT = "resident"
    VISITOR = "visitor"
    CONCIERGE = "concierge"
    PROPERTY_ADMIN = "property_admin"
    CLEANING_STAFF = "cleaning_staff"
    SYSTEM_USER = "system_user"

    DOMAIN_ROLES = [
      OWNER,
      RESIDENT,
      VISITOR,
      CONCIERGE,
      PROPERTY_ADMIN,
      CLEANING_STAFF,
      SYSTEM_USER
    ].freeze

    STAFF_ROLES = [ CONCIERGE, PROPERTY_ADMIN, CLEANING_STAFF ].freeze

    def self.call(person)
      new(person).call
    end

    def self.batch_for(people)
      return {} if people.blank?

      person_ids = people.map(&:id)
      organization_id = people.first.organization_id

      owner_ids = UnitOwnership.where(
        organization_id: organization_id,
        person_id: person_ids,
        status: UnitOwnership::STATUS_ACTIVE
      ).distinct.pluck(:person_id).to_set

      resident_ids = UnitOccupancy.where(
        organization_id: organization_id,
        person_id: person_ids,
        status: OccupancyStatuses::ACTIVE
      ).distinct.pluck(:person_id).to_set

      visitor_ids = VisitorProfile.where(
        organization_id: organization_id,
        person_id: person_ids
      ).distinct.pluck(:person_id).to_set

      people.each_with_object({}) do |person, roles_by_person|
        roles_by_person[person.id] = build_roles(
          owner: owner_ids.include?(person.id),
          resident: resident_ids.include?(person.id),
          visitor: visitor_ids.include?(person.id),
          system_user: person.user_id.present?
        )
      end
    end

    def self.build_roles(owner:, resident:, visitor:, system_user:)
      [].tap do |roles|
        roles << OWNER if owner
        roles << RESIDENT if resident
        roles << VISITOR if visitor
        roles << SYSTEM_USER if system_user
      end
    end

    def initialize(person)
      @person = person
    end

    def call
      self.class.build_roles(
        owner: owner?,
        resident: resident?,
        visitor: visitor?,
        system_user: system_user?
      )
    end

    private

    def owner?
      @person.unit_ownerships.where(status: UnitOwnership::STATUS_ACTIVE).exists?
    end

    def resident?
      @person.unit_occupancies.where(status: OccupancyStatuses::ACTIVE).exists?
    end

    def visitor?
      @person.visitor_profiles.exists?
    end

    def system_user?
      @person.user_id.present?
    end
  end
end
