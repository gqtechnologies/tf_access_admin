# frozen_string_literal: true

module Visits
  class Authorize
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(visit:, actor:, notes: nil)
      @visit = visit
      @actor = actor
      @notes = notes
    end

    def call
      ActiveRecord::Base.transaction do
        from_status = @visit.status
        @visit.authorize!(@actor)
        @visit.save!

        RecordEvent.call(
          visit: @visit,
          event_type: VisitEventTypes::AUTHORIZED,
          from_status: from_status,
          to_status: @visit.status,
          actor: @actor,
          notes: @notes
        )

        @visit
      end
    end
  end
end
