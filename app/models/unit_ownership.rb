# frozen_string_literal: true

# == Schema Information
#
# Table name: unit_ownerships
#
#  id                   :uuid             not null, primary key
#  deleted_at           :datetime
#  ends_at              :date
#  metadata             :jsonb            not null
#  ownership_percentage :decimal(5, 2)    default(100.0), not null
#  starts_at            :date             not null
#  status               :string           default("active"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  created_by_person_id :uuid
#  ended_by_person_id   :uuid
#  organization_id      :uuid             not null
#  person_id            :uuid             not null
#  unit_id              :uuid             not null
#
# Indexes
#
#  index_unit_ownerships_on_created_by_person_id  (created_by_person_id)
#  index_unit_ownerships_on_deleted_at            (deleted_at)
#  index_unit_ownerships_on_ended_by_person_id    (ended_by_person_id)
#  index_unit_ownerships_on_metadata              (metadata) USING gin
#  index_unit_ownerships_on_org_person_status     (organization_id,person_id,status)
#  index_unit_ownerships_on_org_unit_date_range   (organization_id,unit_id,starts_at,ends_at)
#  index_unit_ownerships_on_org_unit_status       (organization_id,unit_id,status)
#  index_unit_ownerships_on_organization_id       (organization_id)
#  index_unit_ownerships_on_person_id             (person_id)
#  index_unit_ownerships_on_unit_id               (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_person_id => people.id)
#  fk_rails_...  (ended_by_person_id => people.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (unit_id => units.id)
#
class UnitOwnership < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization
  acts_as_paranoid

  STATUS_ACTIVE = "active"

  belongs_to :organization
  belongs_to :unit
  belongs_to :person
  belongs_to :created_by_person, class_name: "Person", optional: true
  belongs_to :ended_by_person, class_name: "Person", optional: true

  validates :ownership_percentage, presence: true
  validates :starts_at, presence: true
  validates :status, presence: true

  validates_same_tenant :unit, :person, :created_by_person, :ended_by_person

  validate :ends_on_or_after_starts
  validate :active_ownership_share_within_unit_cap

  private

  def ends_on_or_after_starts
    return if ends_at.blank?
    return if ends_at >= starts_at

    errors.add(:ends_at, "must be on or after starts_at")
  end

  def active_ownership_share_within_unit_cap
    return unless status == STATUS_ACTIVE && unit_id.present? && ownership_percentage.present?

    others = UnitOwnership.where(unit_id: unit_id, organization_id: organization_id, status: STATUS_ACTIVE)
    others = others.where.not(id: id) if persisted?
    total = others.sum(:ownership_percentage).to_d + ownership_percentage.to_d
    return if total <= 100

    errors.add(:ownership_percentage, "sum of active ownership shares on this unit cannot exceed 100%")
  end
end
