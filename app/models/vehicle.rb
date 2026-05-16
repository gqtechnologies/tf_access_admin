# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                      :uuid             not null, primary key
#  authorized_from         :datetime
#  authorized_until        :datetime
#  brand                   :string
#  color                   :string
#  deleted_at              :datetime
#  metadata                :jsonb            not null
#  model                   :string
#  plate_number_ciphertext :text
#  plate_number_digest     :string
#  status                  :string           default("active"), not null
#  vehicle_type            :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  organization_id         :uuid             not null
#  person_id               :uuid
#  unit_id                 :uuid
#
# Indexes
#
#  index_vehicles_on_deleted_at                             (deleted_at)
#  index_vehicles_on_org_person                             (organization_id,person_id)
#  index_vehicles_on_org_status                             (organization_id,status)
#  index_vehicles_on_org_unit                               (organization_id,unit_id)
#  index_vehicles_on_organization_id                        (organization_id)
#  index_vehicles_on_person_id                              (person_id)
#  index_vehicles_on_unit_id                                (unit_id)
#  index_vehicles_unique_plate_digest_per_org_when_present  (organization_id,plate_number_digest) UNIQUE WHERE ((deleted_at IS NULL) AND (plate_number_digest IS NOT NULL))
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (unit_id => units.id)
#
class Vehicle < ApplicationRecord
  include TenantScopedAssociations
  include VehicleTypes

  acts_as_tenant :organization
  acts_as_paranoid

  belongs_to :organization
  belongs_to :person, optional: true
  belongs_to :unit, optional: true

  validates_same_tenant :person, :unit

  validates :vehicle_type, inclusion: { in: VehicleTypes::ALL }, allow_nil: true, if: -> { vehicle_type.present? }
end
