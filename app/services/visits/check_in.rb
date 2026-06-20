# frozen_string_literal: true

module Visits
  class CheckIn
    include ServiceAuthorization

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(visit:, actor:, access_point: nil, access_type: nil, vehicle_plate: nil, notes: nil,
                   check_in_metadata: {})
      @visit = visit
      @actor = actor
      @notes = notes
      @check_in_metadata = OperationalMetadataParams.check_in(
        access_point: access_point,
        access_type: access_type,
        vehicle_plate: vehicle_plate,
        raw: check_in_metadata
      )
    end

    def call
      authorize_visit_action!(@visit, :check_in?)

      ActiveRecord::Base.transaction do
        from_status = @visit.status
        @visit.merge_check_in_metadata!(@check_in_metadata) if @check_in_metadata.present?
        @visit.check_in!(@actor)
        @visit.save!

        RecordEvent.call(
          visit: @visit,
          event_type: VisitEventTypes::CHECKED_IN,
          from_status: from_status,
          to_status: @visit.status,
          actor: @actor,
          notes: @notes,
          metadata: { "check_in" => @visit.check_in_metadata }.compact_blank
        )

        @visit
      end
    end
  end
end
