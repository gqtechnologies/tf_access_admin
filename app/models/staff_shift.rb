# frozen_string_literal: true

# == Schema Information
#
# Table name: staff_shifts
#
#  id                      :uuid             not null, primary key
#  actual_ends_at          :datetime
#  actual_starts_at        :datetime
#  metadata                :jsonb            not null
#  notes                   :text
#  planned_ends_at         :datetime         not null
#  planned_starts_at       :datetime         not null
#  status                  :string           default("scheduled"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  closed_by_person_id     :uuid
#  opened_by_person_id     :uuid
#  organization_id         :uuid             not null
#  person_id               :uuid             not null
#  replaced_by_shift_id    :uuid
#  residential_property_id :uuid             not null
#  staff_assignment_id     :uuid             not null
#
# Indexes
#
#  index_staff_shifts_on_closed_by_person_id         (closed_by_person_id)
#  index_staff_shifts_on_metadata                    (metadata) USING gin
#  index_staff_shifts_on_opened_by_person_id         (opened_by_person_id)
#  index_staff_shifts_on_org_person_planned_range    (organization_id,person_id,planned_starts_at,planned_ends_at)
#  index_staff_shifts_on_org_property_in_progress    (organization_id,residential_property_id,status) WHERE ((status)::text = 'in_progress'::text)
#  index_staff_shifts_on_org_property_planned_range  (organization_id,residential_property_id,planned_starts_at,planned_ends_at)
#  index_staff_shifts_on_organization_id             (organization_id)
#  index_staff_shifts_on_organization_id_and_status  (organization_id,status)
#  index_staff_shifts_on_person_id                   (person_id)
#  index_staff_shifts_on_residential_property_id     (residential_property_id)
#  index_staff_shifts_on_staff_assignment_id         (staff_assignment_id)
#
# Foreign Keys
#
#  fk_rails_...  (closed_by_person_id => people.id)
#  fk_rails_...  (opened_by_person_id => people.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (replaced_by_shift_id => staff_shifts.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#  fk_rails_...  (staff_assignment_id => staff_assignments.id)
#
class StaffShift < ApplicationRecord
  include StaffShiftStatuses
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :staff_assignment
  belongs_to :person
  belongs_to :replaced_by_shift, class_name: "StaffShift", optional: true
  belongs_to :opened_by_person, class_name: "Person", optional: true
  belongs_to :closed_by_person, class_name: "Person", optional: true

  validates :status, presence: true, inclusion: { in: StaffShiftStatuses::ALL }

  validates_same_tenant :residential_property, :staff_assignment, :person, :replaced_by_shift,
                        :opened_by_person, :closed_by_person
end
