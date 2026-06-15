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
class UnitOccupancy < ApplicationRecord
  include OccupancyTypes
  include OccupancyStatuses
  include TenantScopedAssociations

  acts_as_tenant :organization
  acts_as_paranoid

  audited associated_with: :unit,
          only: %i[occupancy_type can_authorize_visits starts_at ends_at status person_id]

  belongs_to :organization
  belongs_to :unit
  belongs_to :person
  belongs_to :source, polymorphic: true, optional: true

  delegate :user, to: :person, allow_nil: true

  validates :occupancy_type, presence: true,
                             inclusion: { in: OccupancyTypes::ALL, message: "admin.unit_occupancies.validations.invalid_occupancy_type" }
  validates :starts_at, presence: true
  validates :status, presence: true,
                     inclusion: { in: OccupancyStatuses::ALL, message: "admin.unit_occupancies.validations.invalid_status" }

  validates_same_tenant :unit, :person, :source

  validate :ends_on_or_after_starts
  validate :no_duplicate_active_occupancy_for_person_on_unit, if: :active_status?

  scope :active_authorizers, lambda { |at: Time.zone.now|
    day_start = at.in_time_zone.beginning_of_day
    day_end = at.in_time_zone.end_of_day

    where(status: OccupancyStatuses::ACTIVE, can_authorize_visits: true)
      .where("#{table_name}.starts_at <= ?", day_end)
      .where("#{table_name}.ends_at IS NULL OR #{table_name}.ends_at >= ?", day_start)
  }

  scope :ordered_for_display, lambda {
    active_first = sanitize_sql_array([
      "CASE WHEN #{table_name}.status = ? THEN 0 ELSE 1 END",
      OccupancyStatuses::ACTIVE
    ])
    order(Arel.sql(active_first), starts_at: :desc, created_at: :desc)
  }

  def self.active_authorizers_for(unit, at: Time.zone.now)
    active_authorizers(at: at).where(unit_id: unit.id, organization_id: unit.organization_id)
  end

  private

  def active_status?
    status == OccupancyStatuses::ACTIVE
  end

  def no_duplicate_active_occupancy_for_person_on_unit
    return if person_id.blank? || unit_id.blank?

    scope = UnitOccupancy.where(
      unit_id: unit_id,
      person_id: person_id,
      organization_id: organization_id,
      status: OccupancyStatuses::ACTIVE
    )
    scope = scope.where.not(id: id) if persisted?
    return unless scope.exists?

    errors.add(:person_id, "admin.unit_occupancies.validations.duplicate_active_person")
  end

  def ends_on_or_after_starts
    return if ends_at.blank? || starts_at.blank?
    return if ends_at >= starts_at

    errors.add(:ends_at, "admin.unit_occupancies.validations.ends_at_before_starts_at")
  end
end
