# frozen_string_literal: true

module StaffShifts
  # Ends the worker's open shift with a handover note for whoever comes next.
  class Close
    class NotOpen < StandardError; end

    def self.call(shift:, actor:, notes: nil)
      person = actor.person_for(shift.organization)
      raise Pundit::NotAuthorizedError unless person && person.id == shift.person_id

      shift.with_lock do
        raise NotOpen unless shift.in_progress?

        now = Time.zone.now
        shift.update!(
          status: StaffShiftStatuses::COMPLETED,
          actual_ends_at: now,
          planned_ends_at: [ shift.planned_ends_at, now ].max,
          closed_by_person: person,
          notes: notes.to_s.strip.presence
        )
      end

      shift
    end
  end
end
