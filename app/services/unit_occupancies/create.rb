# frozen_string_literal: true

module UnitOccupancies
  class Create
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(unit:, occupancy_params:, actor:)
      @unit = unit
      @occupancy_params = occupancy_params.to_h.symbolize_keys
      @actor = actor
    end

    def call
      person = find_person!

      Mutation.with_unit_lock(@unit) do
        occupancy = UnitOccupancy.new(
          Mutation.occupancy_attributes(
            unit: @unit,
            person: person,
            occupancy_params: @occupancy_params
          )
        )
        occupancy.save!
        occupancy
      end
    end

    private

    def find_person!
      person_id = @occupancy_params.fetch(:person_id)
      @unit.organization.people.find(person_id)
    end
  end
end
