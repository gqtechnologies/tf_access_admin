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
      raise NotImplementedError, "UnitOccupancies::Create is not implemented yet"
    end
  end
end
