# frozen_string_literal: true

module UnitOccupancies
  class Update
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(occupancy:, occupancy_params:, actor:)
      @occupancy = occupancy
      @occupancy_params = occupancy_params.to_h.symbolize_keys
      @actor = actor
    end

    def call
      raise NotImplementedError, "UnitOccupancies::Update is not implemented yet"
    end
  end
end
