# frozen_string_literal: true

module UnitOwnerships
  class Update
    PERMITTED_ATTRIBUTES = %i[ownership_percentage starts_at ends_at status].freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(ownership:, ownership_params:, actor: nil)
      @ownership = ownership
      @ownership_params = ownership_params.to_h.symbolize_keys
      @actor = actor
    end

    def call
      Mutation.with_unit_lock(@ownership.unit) do
        @ownership.assign_attributes(permitted_attributes)
        @ownership.save!
        @ownership
      end
    end

    private

    def permitted_attributes
      @ownership_params.slice(*PERMITTED_ATTRIBUTES)
    end
  end
end
