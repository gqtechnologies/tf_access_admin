# frozen_string_literal: true

module Parcels
  # People who may pick a parcel up for a unit: holders of a currently valid
  # active occupancy with can_withdraw_parcels, and approved, currently valid
  # authorized people of the unit with that flag. Owners without an occupancy
  # carry no such flag and are therefore not eligible.
  # See openspec/changes/2026-10-02-parcel-deliveries/design.md D4.
  class EligibleWithdrawers
    def self.call(unit:)
      occupancies = Authorization::ActiveRelationships
                    .active_occupancies_of_unit(unit)
                    .where(can_withdraw_parcels: true)

      authorized = unit.authorized_residents.currently_valid.where(can_withdraw_parcels: true)

      Person.where(id: occupancies.select(:person_id)).or(Person.where(id: authorized.select(:person_id))).order(:display_name)
    end

    def self.include?(unit:, person_id:)
      person_id.present? && call(unit: unit).exists?(id: person_id)
    end
  end
end
