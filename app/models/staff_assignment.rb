# frozen_string_literal: true

# == Schema Information
#
# Table name: staff_assignments
#
#  id                      :uuid             not null, primary key
#  ends_at                 :date
#  metadata                :jsonb            not null
#  staff_type              :string           not null
#  starts_at               :date
#  status                  :string           default("active"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  organization_id         :uuid             not null
#  person_id               :uuid             not null
#  residential_property_id :uuid             not null
#
# Indexes
#
#  idx_on_organization_id_person_id_status_36b5c5bfed   (organization_id,person_id,status)
#  index_staff_assignments_on_metadata                  (metadata) USING gin
#  index_staff_assignments_on_org_property_type_status  (organization_id,residential_property_id,staff_type,status)
#  index_staff_assignments_on_organization_id           (organization_id)
#  index_staff_assignments_on_person_id                 (person_id)
#  index_staff_assignments_on_residential_property_id   (residential_property_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#
class StaffAssignment < ApplicationRecord
  include StaffTypes
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :person
  belongs_to :residential_property

  validates :staff_type, presence: true, inclusion: { in: StaffTypes::ALL }

  validates_same_tenant :person, :residential_property

  has_many :staff_shifts, dependent: :restrict_with_error
end
