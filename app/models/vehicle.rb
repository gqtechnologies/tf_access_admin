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
#  index_vehicles_on_organization_id  (organization_id)
#  index_vehicles_on_person_id        (person_id)
#  index_vehicles_on_unit_id          (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (unit_id => units.id)
#
class Vehicle < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :person, optional: true
  belongs_to :unit, optional: true
end
