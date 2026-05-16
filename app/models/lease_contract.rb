# frozen_string_literal: true

# == Schema Information
#
# Table name: lease_contracts
#
#  id                       :uuid             not null, primary key
#  can_authorize_visits     :boolean          default(TRUE), not null
#  can_reserve_common_areas :boolean          default(TRUE), not null
#  can_withdraw_parcels     :boolean          default(TRUE), not null
#  ends_at                  :date
#  metadata                 :jsonb            not null
#  starts_at                :date             not null
#  status                   :string           default("draft"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  created_by_person_id     :uuid
#  lessee_person_id         :uuid             not null
#  lessor_person_id         :uuid
#  organization_id          :uuid             not null
#  terminated_by_person_id  :uuid
#  unit_id                  :uuid             not null
#
# Indexes
#
#  index_lease_contracts_on_created_by_person_id         (created_by_person_id)
#  index_lease_contracts_on_lessee_person_id             (lessee_person_id)
#  index_lease_contracts_on_lessor_person_id             (lessor_person_id)
#  index_lease_contracts_on_metadata                     (metadata) USING gin
#  index_lease_contracts_on_org_lessee_person_status     (organization_id,lessee_person_id,status)
#  index_lease_contracts_on_org_status_ends_at           (organization_id,status,ends_at)
#  index_lease_contracts_on_org_unit_date_range          (organization_id,unit_id,starts_at,ends_at)
#  index_lease_contracts_on_org_unit_unique_when_active  (organization_id,unit_id) UNIQUE WHERE ((status)::text = 'active'::text)
#  index_lease_contracts_on_organization_id              (organization_id)
#  index_lease_contracts_on_terminated_by_person_id      (terminated_by_person_id)
#  index_lease_contracts_on_unit_id                      (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_person_id => people.id)
#  fk_rails_...  (lessee_person_id => people.id)
#  fk_rails_...  (lessor_person_id => people.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (terminated_by_person_id => people.id)
#  fk_rails_...  (unit_id => units.id)
#
class LeaseContract < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :unit
  belongs_to :lessee_person, class_name: "Person"
  belongs_to :lessor_person, class_name: "Person", optional: true
  belongs_to :created_by_person, class_name: "Person", optional: true
  belongs_to :terminated_by_person, class_name: "Person", optional: true

  validates :starts_at, presence: true
  validates :status, presence: true

  validates_same_tenant :unit, :lessee_person, :lessor_person, :created_by_person, :terminated_by_person

  validate :ends_on_or_after_starts

  private

  def ends_on_or_after_starts
    return if ends_at.blank?
    return if ends_at >= starts_at

    errors.add(:ends_at, "must be on or after starts_at")
  end
end
