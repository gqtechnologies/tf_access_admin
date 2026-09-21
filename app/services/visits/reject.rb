# frozen_string_literal: true

module Visits
  # A unit authorizer (or administrator) declines a pending visit request.
  # Distinct from Cancel: the history tells "rejected" apart from "cancelled".
  class Reject
    include ServiceAuthorization

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(visit:, actor:, notes: nil)
      @visit = visit
      @actor = actor
      @notes = notes
    end

    def call
      authorize_visit_action!(@visit, :reject?)

      ActiveRecord::Base.transaction do
        from_status = @visit.status
        @visit.reject!
        @visit.save!

        RecordEvent.call(
          visit: @visit,
          event_type: VisitEventTypes::REJECTED,
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
