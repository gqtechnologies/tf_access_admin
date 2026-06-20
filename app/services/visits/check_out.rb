# frozen_string_literal: true

module Visits
  class CheckOut
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(visit:, actor:, check_out_metadata: {}, notes: nil)
      @visit = visit
      @actor = actor
      @check_out_metadata = check_out_metadata.to_h.symbolize_keys
      @notes = notes
    end

    def call
      ActiveRecord::Base.transaction do
        from_status = @visit.status
        @visit.merge_check_out_metadata!(@check_out_metadata) if @check_out_metadata.present?
        @visit.check_out!(@actor)
        @visit.save!

        RecordEvent.call(
          visit: @visit,
          event_type: VisitEventTypes::CHECKED_OUT,
          from_status: from_status,
          to_status: @visit.status,
          actor: @actor,
          notes: @notes,
          metadata: { "check_out" => @visit.check_out_metadata }.compact_blank
        )

        @visit
      end
    end
  end
end
