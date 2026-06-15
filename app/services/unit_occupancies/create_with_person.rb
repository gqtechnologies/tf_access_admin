# frozen_string_literal: true

module UnitOccupancies
  class CreateWithPerson
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(unit:, occupancy_params:, person_params:, actor:)
      @unit = unit
      @occupancy_params = occupancy_params.to_h.symbolize_keys
      @person_params = person_params.to_h.symbolize_keys
      @actor = actor
    end

    def call
      raise NotImplementedError, "UnitOccupancies::CreateWithPerson is not implemented yet"
    end
  end
end
