# frozen_string_literal: true

module LeaseContracts
  # Ends an active lease on a date (today by default, never before it started)
  # and closes the tenant's occupancy at the end of that day.
  class Terminate
    class NotActive < StandardError; end

    def self.call(lease:, actor:, on: nil)
      lease.with_lock do
        raise NotActive unless lease.status == LeaseStatuses::ACTIVE

        zone = ActiveSupport::TimeZone[lease.unit.residential_property.timezone.to_s] || Time.zone
        date = [ (on.presence && Date.parse(on.to_s)) || zone.today, lease.starts_at ].max

        lease.update!(
          status: LeaseStatuses::TERMINATED,
          ends_at: date,
          terminated_by_person: actor.person_for(lease.organization)
        )
        lease.occupancy&.update!(ends_at: zone.local(date.year, date.month, date.day).end_of_day)
      end

      lease
    end
  end
end
