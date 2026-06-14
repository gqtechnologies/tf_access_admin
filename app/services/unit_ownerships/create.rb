# frozen_string_literal: true

module UnitOwnerships
  class Create
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(unit:, ownership_params:, actor:)
      @unit = unit
      @ownership_params = ownership_params.to_h.symbolize_keys
      @actor = actor
    end

    def call
      person = find_person!
      created_by = Mutation.actor_person(@actor, @unit.organization)

      Mutation.with_unit_lock(@unit) do
        ownership = UnitOwnership.new(
          Mutation.ownership_attributes(
            unit: @unit,
            person: person,
            ownership_params: @ownership_params,
            created_by_person: created_by
          )
        )
        ownership.save!
        ownership
      end
    end

    private

    def find_person!
      person_id = @ownership_params.fetch(:person_id)
      @unit.organization.people.find(person_id)
    end
  end
end
