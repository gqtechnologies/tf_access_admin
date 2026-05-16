# frozen_string_literal: true

# == Schema Information
#
# Table name: visits
#
#  id                               :uuid             not null, primary key
#  actual_ended_at                  :datetime
#  actual_started_at                :datetime
#  approved_at                      :datetime
#  authorization_method             :string
#  concierge_validated_at           :datetime
#  metadata                         :jsonb            not null
#  notes                            :text
#  rejected_at                      :datetime
#  rejection_reason                 :text
#  scheduled_ends_at                :datetime
#  scheduled_starts_at              :datetime         not null
#  status                           :string           default("pending"), not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  approved_by_person_id            :uuid
#  concierge_validated_by_person_id :uuid
#  created_by_person_id             :uuid
#  organization_id                  :uuid             not null
#  rejected_by_person_id            :uuid
#  residential_property_id          :uuid             not null
#  responsible_person_id            :uuid
#  staff_shift_id                   :uuid
#  unit_id                          :uuid             not null
#
# Indexes
#
#  index_visits_on_approved_by_person_id                 (approved_by_person_id)
#  index_visits_on_concierge_validated_by_person_id      (concierge_validated_by_person_id)
#  index_visits_on_created_by_person_id                  (created_by_person_id)
#  index_visits_on_metadata                              (metadata) USING gin
#  index_visits_on_org_property_pending_statuses         (organization_id,residential_property_id,scheduled_starts_at) WHERE ((status)::text = ANY ((ARRAY['pending'::character varying, 'concierge_validation_pending'::character varying, 'resident_notified'::character varying])::text[]))
#  index_visits_on_org_property_status_scheduled_starts  (organization_id,residential_property_id,status,scheduled_starts_at)
#  index_visits_on_org_unit_scheduled_starts             (organization_id,unit_id,scheduled_starts_at)
#  index_visits_on_organization_id                       (organization_id)
#  index_visits_on_organization_id_and_staff_shift_id    (organization_id,staff_shift_id)
#  index_visits_on_rejected_by_person_id                 (rejected_by_person_id)
#  index_visits_on_residential_property_id               (residential_property_id)
#  index_visits_on_responsible_person_id                 (responsible_person_id)
#  index_visits_on_unit_id                               (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_person_id => people.id)
#  fk_rails_...  (concierge_validated_by_person_id => people.id)
#  fk_rails_...  (created_by_person_id => people.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (rejected_by_person_id => people.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#  fk_rails_...  (responsible_person_id => people.id)
#  fk_rails_...  (staff_shift_id => staff_shifts.id)
#  fk_rails_...  (unit_id => units.id)
#
class Visit < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :unit
  belongs_to :created_by_person, class_name: "Person", optional: true
  belongs_to :responsible_person, class_name: "Person", optional: true
  belongs_to :approved_by_person, class_name: "Person", optional: true
  belongs_to :concierge_validated_by_person, class_name: "Person", optional: true
  belongs_to :rejected_by_person, class_name: "Person", optional: true
  belongs_to :staff_shift, optional: true

  has_many :visit_participants
  has_many :visit_status_histories
  has_one  :visit_recurrence, dependent: :destroy

  validates_same_tenant :residential_property, :unit, :created_by_person, :responsible_person,
                        :approved_by_person, :concierge_validated_by_person, :rejected_by_person,
                        :staff_shift

  validate :scheduled_range_coherent

  private

  def scheduled_range_coherent
    return if scheduled_ends_at.blank?
    return if scheduled_ends_at >= scheduled_starts_at

    errors.add(:scheduled_ends_at, "must be on or after scheduled_starts_at")
  end
end
