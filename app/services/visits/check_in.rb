# frozen_string_literal: true

module Visits
  class CheckIn
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(visit:, actor:, check_in_metadata: {}, notes: nil)
      @visit = visit
      @actor = actor
      @check_in_metadata = check_in_metadata.to_h.symbolize_keys
      @notes = notes
    end

    def call
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
