# frozen_string_literal: true

module Properties
  module Setup
    # Transitions a property from draft to configured after wizard confirmation.
    class Configure < Base
      def initialize(actor:, property:)
        super(actor: actor)
        @property = property
      end

      def call
        authorize_setup_property!(@property)

        unless @property.status == PropertyStatuses::DRAFT
          @property.errors.add(:status, :invalid_transition)
          return Result.invalid(@property)
        end

        @property.status = PropertyStatuses::CONFIGURED
        WizardState.merge!(@property, current_step: 5, confirmed_at: Time.current.iso8601)

        save_property(@property)
      end
    end
  end
end
