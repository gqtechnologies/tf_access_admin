# frozen_string_literal: true

module StaffShifts
  # A front-desk worker starts their shift on a property where they hold a
  # current staff assignment. One shift may be open per person; there is no
  # planning, so the planned range is the actual start until it closes.
  class Open
    class NotAssigned < StandardError; end
    class AlreadyOpen < StandardError; end

    def self.call(property:, actor:)
      person = actor.person_for(property.organization)
      assignment = person && StaffAssignment.currently_active.find_by(person: person, residential_property: property)
      raise NotAssigned unless assignment
      raise AlreadyOpen if StaffShift.open_now.exists?(person: person)

      now = Time.zone.now
      StaffShift.create!(
        organization: property.organization,
        residential_property: property,
        staff_assignment: assignment,
        person: person,
        opened_by_person: person,
        status: StaffShiftStatuses::IN_PROGRESS,
        planned_starts_at: now,
        planned_ends_at: now,
        actual_starts_at: now
      )
    end
  end
end
