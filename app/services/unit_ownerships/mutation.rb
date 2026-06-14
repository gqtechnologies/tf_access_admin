# frozen_string_literal: true

module UnitOwnerships
  module Mutation
    module_function

    def with_unit_lock(unit)
      result = nil
      unit.with_lock do
        result = yield
      end
      result
    end

    def actor_person(actor, organization)
      return nil if actor.blank? || organization.blank?

      actor.person_for(organization)
    end

    def ownership_attributes(unit:, person:, ownership_params:, created_by_person: nil)
      {
        organization: unit.organization,
        unit: unit,
        person: person,
        ownership_percentage: ownership_params[:ownership_percentage].presence || 100,
        starts_at: ownership_params[:starts_at].presence || Date.current,
        ends_at: ownership_params[:ends_at].presence,
        status: ownership_params[:status].presence || UnitOwnership::STATUS_ACTIVE,
        created_by_person: created_by_person
      }
    end
  end
end
