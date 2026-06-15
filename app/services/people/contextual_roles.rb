# frozen_string_literal: true

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

    def initialize(person)
      @person = person
    end

    def call
      [].tap do |roles|
        roles << OWNER if owner?
        roles << RESIDENT if resident?
        roles << VISITOR if visitor?
        roles << SYSTEM_USER if system_user?
        roles << CONCIERGE if concierge?
        roles << PROPERTY_ADMIN if property_admin?
        roles << CLEANING_STAFF if cleaning_staff?
      end
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

    # Prepared for future property staff assignments (no table in this change).
    def concierge?
      false
    end

    def property_admin?
      false
    end

    def cleaning_staff?
      false
    end
  end
end
