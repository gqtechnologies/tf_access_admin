# frozen_string_literal: true

module LeaseContracts
  # Registers a lease as a draft: the unit, the tenant (resolved or created by
  # email like a visitor), optionally the landlord among the unit's current
  # owners, the dates and the permissions the tenant's occupancy will get.
  class Create
    class InvalidLessor < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(unit:, actor:, lessee_params:, attributes:)
      @unit = unit
      @actor = actor
      @lessee_params = lessee_params.to_h.symbolize_keys.slice(:name, :email, :document, :phone)
      @attributes = attributes.to_h.symbolize_keys.slice(
        :lessor_person_id, :starts_at, :ends_at, :can_authorize_visits, :can_reserve_common_areas, :can_withdraw_parcels
      )
    end

    def call
      ActiveRecord::Base.transaction do
        lessee = Residents::ResolveVisitorPerson.call(organization: @unit.organization, visitor_params: @lessee_params)

        LeaseContract.create!(
          organization: @unit.organization,
          unit: @unit,
          lessee_person: lessee,
          lessor_person: lessor,
          created_by_person: @actor.person_for(@unit.organization),
          status: LeaseStatuses::DRAFT,
          starts_at: @attributes[:starts_at],
          ends_at: @attributes[:ends_at].presence,
          can_authorize_visits: boolean(:can_authorize_visits),
          can_reserve_common_areas: boolean(:can_reserve_common_areas),
          can_withdraw_parcels: boolean(:can_withdraw_parcels)
        )
      end
    end

    private

    def lessor
      id = @attributes[:lessor_person_id].presence
      return nil unless id

      owners = Authorization::ActiveRelationships.active_ownerships_of_unit(@unit).pluck(:person_id)
      raise InvalidLessor unless owners.include?(id)

      Person.find(id)
    end

    # Permissions default to granted, like the column defaults.
    def boolean(key)
      return true unless @attributes.key?(key)

      ActiveModel::Type::Boolean.new.cast(@attributes[key]) != false
    end
  end
end
