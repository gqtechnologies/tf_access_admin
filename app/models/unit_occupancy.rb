# frozen_string_literal: true

# == Schema Information
#
# Table name: unit_occupancies
#
#  id                       :uuid             not null, primary key
#  can_authorize_visits     :boolean          default(FALSE), not null
#  can_reserve_common_areas :boolean          default(FALSE), not null
#  can_withdraw_parcels     :boolean          default(FALSE), not null
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
#  index_unit_occupancies_on_metadata               (metadata) USING gin
#  index_unit_occupancies_on_org_person_status      (organization_id,person_id,status)
#  index_unit_occupancies_on_org_source             (organization_id,source_type,source_id)
#  index_unit_occupancies_on_org_unit_status_dates  (organization_id,unit_id,status,starts_at,ends_at)
#  index_unit_occupancies_on_organization_id        (organization_id)
#  index_unit_occupancies_on_person_id              (person_id)
#  index_unit_occupancies_on_unit_id                (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (unit_id => units.id)
#
class UnitOccupancy < ApplicationRecord
  include OccupancyTypes
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :unit
  belongs_to :person
  belongs_to :source, polymorphic: true, optional: true

  delegate :user, to: :person, allow_nil: true

  validates :occupancy_type, presence: true, inclusion: { in: OccupancyTypes::ALL }
  validates :starts_at, presence: true
  validates :status, presence: true

  validates_same_tenant :unit, :person, :source

  validate :ends_on_or_after_starts

  private

  def ends_on_or_after_starts
    return if ends_at.blank? || starts_at.blank?
    return if ends_at >= starts_at

    errors.add(:ends_at, "must be on or after starts_at")
  end
end
