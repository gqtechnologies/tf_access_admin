# frozen_string_literal: true

# == Schema Information
#
# Table name: unit_occupancies
#
#  id                       :uuid             not null, primary key
#  can_authorize_visits     :boolean          default(FALSE), not null
#  can_reserve_common_areas :boolean          default(FALSE), not null
#  can_withdraw_parcels     :boolean          default(FALSE), not null
#  deleted_at               :datetime
#  ends_at                  :datetime
#  metadata                 :jsonb            not null
#  occupancy_type           :string           not null
#  source_type              :string
#  starts_at                :datetime         not null
#  status                   :string           default("active"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  organization_id          :uuid             not null
#  person_id                :uuid             not null
#  source_id                :uuid
#  unit_id                  :uuid             not null
#
# Indexes
#
#  index_unit_occupancies_on_deleted_at                   (deleted_at)
#  index_unit_occupancies_on_metadata                     (metadata) USING gin
#  index_unit_occupancies_on_org_person_status            (organization_id,person_id,status)
#  index_unit_occupancies_on_org_source                   (organization_id,source_type,source_id)
#  index_unit_occupancies_on_org_unit_person_not_deleted  (organization_id,unit_id,person_id) UNIQUE WHERE (deleted_at IS NULL)
#  index_unit_occupancies_on_org_unit_status_dates        (organization_id,unit_id,status,starts_at,ends_at)
#  index_unit_occupancies_on_organization_id              (organization_id)
#  index_unit_occupancies_on_person_id                    (person_id)
#  index_unit_occupancies_on_unit_id                      (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (unit_id => units.id)
#
require "test_helper"

class UnitOccupancyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "Occupancy Model Property",
      property_type: PropertyTypes::BUILDING,
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    @unit = Unit.create!(
      organization: @organization,
      residential_property: @property,
      identifier: "OCC-MODEL-101",
      unit_type: UnitTypes::APARTMENT,
      status: UnitStatuses::AVAILABLE
    )
    @person = Person.create!(
      organization: @organization,
      display_name: "Occupancy Model Person",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
    @other_person = Person.create!(
      organization: @organization,
      display_name: "Other Occupancy Person",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "valid occupancy with new occupancy types" do
    OccupancyTypes::ALL.each do |occupancy_type|
      occupancy = build_occupancy(occupancy_type: occupancy_type)

      assert occupancy.valid?, "expected #{occupancy_type} to be valid: #{occupancy.errors.full_messages}"
    end
  end

  test "rejects legacy occupancy types" do
    occupancy = build_occupancy
    occupancy.occupancy_type = "owner"

    assert_not occupancy.valid?
    assert_includes occupancy.errors[:occupancy_type], validation_key("invalid_occupancy_type")
  end

  test "rejects invalid status" do
    occupancy = build_occupancy(status: "archived")

    assert_not occupancy.valid?
    assert_includes occupancy.errors[:status], validation_key("invalid_status")
  end

  test "rejects ends_at before starts_at" do
    occupancy = build_occupancy(
      starts_at: Time.zone.parse("2026-06-10 12:00"),
      ends_at: Time.zone.parse("2026-06-09 12:00")
    )

    assert_not occupancy.valid?
    assert_includes occupancy.errors[:ends_at], validation_key("ends_at_before_starts_at")
  end

  test "rejects duplicate active occupancy for same person and unit" do
    create_occupancy!

    duplicate = build_occupancy

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:person_id], validation_key("duplicate_active_person")
  end

  test "allows reactivating the same occupancy after inactivation" do
    occupancy = create_occupancy!
    occupancy.update!(status: OccupancyStatuses::INACTIVE)

    occupancy.status = OccupancyStatuses::ACTIVE

    assert occupancy.valid?
    assert occupancy.save
  end

  test "partial unique index prevents two non-deleted occupancies for same person and unit" do
    create_occupancy!(person: @person, status: OccupancyStatuses::INACTIVE)

    assert_raises ActiveRecord::RecordNotUnique do
      UnitOccupancy.create!(
        organization: @organization,
        unit: @unit,
        person: @person,
        occupancy_type: OccupancyTypes::TENANT,
        starts_at: Time.current,
        status: OccupancyStatuses::INACTIVE
      )
    end
  end

  test "soft delete allows creating a new occupancy for same person and unit" do
    occupancy = create_occupancy!
    occupancy.destroy

    replacement = build_occupancy

    assert replacement.save
  end

  test "destroy performs soft delete" do
    occupancy = create_occupancy!

    assert_no_difference -> { UnitOccupancy.unscoped.count } do
      occupancy.destroy
    end

    assert_predicate occupancy.reload, :deleted?
    assert_nil UnitOccupancy.find_by(id: occupancy.id)
    assert UnitOccupancy.unscoped.find_by(id: occupancy.id)
  end

  test "active_authorizers_for returns occupancies that can authorize visits today" do
    today = Time.zone.parse("2026-06-14 15:00")

    authorizer = create_occupancy!(
      can_authorize_visits: true,
      starts_at: today.beginning_of_day,
      ends_at: nil
    )
    create_occupancy!(
      person: @other_person,
      can_authorize_visits: false,
      starts_at: today.beginning_of_day
    )

    future_person = Person.create!(
      organization: @organization,
      display_name: "Future Authorizer",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
    create_occupancy!(
      person: future_person,
      can_authorize_visits: true,
      starts_at: today.end_of_day + 1.day
    )

    expired_person = Person.create!(
      organization: @organization,
      display_name: "Expired Authorizer",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
    create_occupancy!(
      person: expired_person,
      can_authorize_visits: true,
      starts_at: today.beginning_of_day - 10.days,
      ends_at: today.beginning_of_day - 1.second
    )

    inactive_person = Person.create!(
      organization: @organization,
      display_name: "Inactive Authorizer",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
    create_occupancy!(
      person: inactive_person,
      can_authorize_visits: true,
      starts_at: today.beginning_of_day,
      status: OccupancyStatuses::INACTIVE
    )

    results = UnitOccupancy.active_authorizers_for(@unit, at: today)

    assert_equal [ authorizer.id ], results.pluck(:id)
  end

  test "active_authorizers_for excludes soft-deleted occupancies" do
    today = Time.zone.parse("2026-06-14 15:00")
    occupancy = create_occupancy!(
      can_authorize_visits: true,
      starts_at: today.beginning_of_day
    )
    occupancy.destroy

    assert_empty UnitOccupancy.active_authorizers_for(@unit, at: today)
  end

  test "audited tracks key fields associated with unit" do
    occupancy = create_occupancy!

    assert_difference -> { occupancy.audits.count }, +1 do
      occupancy.update!(can_authorize_visits: true)
    end

    audit = occupancy.audits.last
    assert_equal @unit, audit.associated
    assert_includes audit.audited_changes.keys, "can_authorize_visits"
  end

  private

  def build_occupancy(**attrs)
    defaults = {
      organization: @organization,
      unit: @unit,
      person: @person,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: Time.current,
      status: OccupancyStatuses::ACTIVE
    }

    UnitOccupancy.new(defaults.merge(attrs))
  end

  def create_occupancy!(**attrs)
    build_occupancy(**attrs).tap(&:save!)
  end

  def validation_key(name)
    "admin.unit_occupancies.validations.#{name}"
  end
end
