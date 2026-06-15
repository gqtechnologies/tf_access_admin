# frozen_string_literal: true

module UnitOccupancies
  class Update
    PERMITTED_ATTRIBUTES = Mutation::OCCUPANCY_ASSIGNMENT_KEYS

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(occupancy:, occupancy_params:, actor: nil)
      @occupancy = occupancy
      @occupancy_params = occupancy_params.to_h.symbolize_keys
      @actor = actor
    end

    def call
      Mutation.with_unit_lock(@occupancy.unit) do
        assign_normalized_attributes
        @occupancy.save!
        @occupancy
      end
    end

    private

    def assign_normalized_attributes
      attrs = @occupancy_params.slice(*PERMITTED_ATTRIBUTES)
      unit = @occupancy.unit

      @occupancy.assign_attributes(
        attrs.except(:starts_at, :ends_at, :can_authorize_visits)
      )

      if attrs.key?(:can_authorize_visits)
        @occupancy.can_authorize_visits = Mutation.cast_boolean(attrs[:can_authorize_visits])
      end

      if attrs.key?(:starts_at)
        @occupancy.starts_at = Mutation.normalize_starts_at(attrs[:starts_at], unit)
      end

      if attrs.key?(:ends_at)
        @occupancy.ends_at = Mutation.normalize_ends_at(attrs[:ends_at], unit)
      end
    end
  end
end
