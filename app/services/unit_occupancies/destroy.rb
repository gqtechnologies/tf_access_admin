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
      Mutation.with_unit_lock(@occupancy.unit) do
        @occupancy.destroy!
        @occupancy
      end
    end
  end
end
