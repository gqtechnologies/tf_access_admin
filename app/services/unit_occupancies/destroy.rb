# frozen_string_literal: true

module UnitOccupancies
  class Destroy
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(occupancy:, actor: nil)
      @occupancy = occupancy
      @actor = actor
    end

    def call
      raise NotImplementedError, "UnitOccupancies::Destroy is not implemented yet (soft delete via acts_as_paranoid)"
    end
  end
end
