# frozen_string_literal: true

module UnitOwnerships
  class Destroy
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(ownership:, actor: nil)
      @ownership = ownership
      @actor = actor
    end

    def call
      Mutation.with_unit_lock(@ownership.unit) do
        @ownership.destroy!
        @ownership
      end
    end
  end
end
