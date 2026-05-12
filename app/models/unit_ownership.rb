# frozen_string_literal: true

# == Schema Information
#
# Table name: unit_ownerships
#
#  id                   :uuid             not null, primary key
#  ends_at              :date
#  metadata             :jsonb            not null
#  ownership_percentage :decimal(5, 2)    default(100.0), not null
#  starts_at            :date             not null
#  status               :string           default("active"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  created_by_id        :uuid
#  ended_by_id          :uuid
#  organization_id      :uuid             not null
#  person_id            :uuid             not null
#  unit_id              :uuid             not null
#
# Indexes
#
#  index_unit_ownerships_on_created_by_id        (created_by_id)
#  index_unit_ownerships_on_ended_by_id          (ended_by_id)
#  index_unit_ownerships_on_metadata             (metadata) USING gin
#  index_unit_ownerships_on_org_person_status    (organization_id,person_id,status)
#  index_unit_ownerships_on_org_unit_date_range  (organization_id,unit_id,starts_at,ends_at)
#  index_unit_ownerships_on_org_unit_status      (organization_id,unit_id,status)
#  index_unit_ownerships_on_organization_id      (organization_id)
#  index_unit_ownerships_on_person_id            (person_id)
#  index_unit_ownerships_on_unit_id              (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (ended_by_id => users.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (unit_id => units.id)
#
class UnitOwnership < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :unit
  belongs_to :person
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :ended_by, class_name: "User", optional: true

  validates :ownership_percentage, presence: true
  validates :starts_at, presence: true
  validates :status, presence: true
end
