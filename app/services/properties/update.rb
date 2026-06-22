# frozen_string_literal: true

module Properties
  # Applies descriptive changes and ordinary active/inactive transitions to a
  # property (improve-property-foundation §3.2). Archiving is intentionally not
  # an ordinary update and must go through {Properties::Archive} (§3.6).
  class Update < Base
    def initialize(actor:, property:, attributes:)
      super(actor: actor)
      @property = property
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      authorize!(@property, :update?)

      @property.assign_attributes(descriptive_attributes(@attributes))
      apply_status(@attributes[:status].presence)

      # §2.7: organization_id is never assignable here, so the tenant cannot move.
      return Result.invalid(@property) if @property.errors.any?

      save_property(@property)
    end

    private

    # §3.6: ordinary updates only flip between active and inactive. A request to
    # archive through the generic update is rejected with a field error so the
    # caller routes it to Properties::Archive.
    def apply_status(requested_status)
      return if requested_status.nil?

      if requested_status == PropertyStatuses::ARCHIVED
        @property.errors.add(:status, :archive_requires_service)
        return
      end

      @property.status = requested_status
    end
  end
end
