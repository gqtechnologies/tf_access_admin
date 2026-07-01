# frozen_string_literal: true

module Properties
  module Setup
    # Creates a minimal automatic unit batch for wizard step 3.
    class ApplyAutomaticUnits < Base
      def initialize(actor:, property:, count: nil)
        super(actor: actor)
        @property = property
        @count = count
      end

      def call
        authorize_setup_property!(@property)
        return Result.success(@property) if @property.units.any?

        # +count+ arrives from params as a string (e.g. "4"); coerce before
        # comparing. Fall back to the wizard's estimated units when unset.
        requested = @count.to_i
        requested = WizardState.estimated_units(@property).to_i if requested <= 0
        total = [ requested, 1 ].max

        total.times do |index|
          result = Units::Create.call(
            actor: @actor,
            property: @property,
            attributes: {
              identifier: (101 + index).to_s,
              unit_type: UnitTypes::APARTMENT
            }
          )
          return Result.invalid(@property) unless result.success?
        end

        Result.success(@property)
      end
    end
  end
end
