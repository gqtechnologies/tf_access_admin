# frozen_string_literal: true

module LeaseContracts
  # Puts a draft lease in force: the tenant gets an active "tenant" occupancy
  # of the unit for the lease's dates with the lease's permissions, linked to
  # the lease as its source.
  class Activate
    class NotDraft < StandardError; end

    def self.call(lease:)
      lease.with_lock do
        raise NotDraft unless lease.status == LeaseStatuses::DRAFT

        zone = ActiveSupport::TimeZone[lease.unit.residential_property.timezone.to_s] || Time.zone
        UnitOccupancy.create!(
          organization: lease.organization,
          unit: lease.unit,
          person: lease.lessee_person,
          source: lease,
          occupancy_type: OccupancyTypes::TENANT,
          status: OccupancyStatuses::ACTIVE,
          starts_at: zone.local(lease.starts_at.year, lease.starts_at.month, lease.starts_at.day),
          ends_at: lease.ends_at && zone.local(lease.ends_at.year, lease.ends_at.month, lease.ends_at.day).end_of_day,
          can_authorize_visits: lease.can_authorize_visits,
          can_reserve_common_areas: lease.can_reserve_common_areas,
          can_withdraw_parcels: lease.can_withdraw_parcels
        )
        lease.update!(status: LeaseStatuses::ACTIVE)
      end

      lease
    end
  end
end
