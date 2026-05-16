# frozen_string_literal: true

# == Schema Information
#
# Table name: access_events
#
#  id                      :uuid             not null, primary key
#  event_type              :string           not null
#  ip_address              :inet
#  metadata                :jsonb            not null
#  notes                   :text
#  occurred_at             :datetime         not null
#  result                  :string           default("success"), not null
#  source                  :string           default("web"), not null
#  user_agent              :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  organization_id         :uuid             not null
#  recorded_by_person_id   :uuid
#  residential_property_id :uuid             not null
#  staff_shift_id          :uuid
#  unit_id                 :uuid
#  vehicle_id              :uuid
#  visit_id                :uuid
#  visit_participant_id    :uuid
#  visitor_profile_id      :uuid
#
# Indexes
#
#  index_access_events_on_metadata                     (metadata) USING gin
#  index_access_events_on_org_property_occurred_at     (organization_id,residential_property_id,occurred_at)
#  index_access_events_on_org_type_result_occurred_at  (organization_id,event_type,result,occurred_at)
#  index_access_events_on_org_unit_occurred_at         (organization_id,unit_id,occurred_at)
#  index_access_events_on_org_visit_occurred_at        (organization_id,visit_id,occurred_at)
#  index_access_events_on_organization_id              (organization_id)
#  index_access_events_on_recorded_by_person_id        (recorded_by_person_id)
#  index_access_events_on_residential_property_id      (residential_property_id)
#  index_access_events_on_unit_id                      (unit_id)
#  index_access_events_on_vehicle_id                   (vehicle_id)
#  index_access_events_on_visit_id                     (visit_id)
#  index_access_events_on_visit_participant_id         (visit_participant_id)
#  index_access_events_on_visitor_profile_id           (visitor_profile_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (recorded_by_person_id => people.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#  fk_rails_...  (staff_shift_id => staff_shifts.id)
#  fk_rails_...  (unit_id => units.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#  fk_rails_...  (visit_id => visits.id)
#  fk_rails_...  (visit_participant_id => visit_participants.id)
#  fk_rails_...  (visitor_profile_id => visitor_profiles.id)
#
class AccessEvent < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :unit, optional: true
  belongs_to :visit, optional: true
  belongs_to :visit_participant, optional: true
  belongs_to :visitor_profile, optional: true
  belongs_to :vehicle, optional: true
  belongs_to :recorded_by_person, class_name: "Person", optional: true
  belongs_to :staff_shift, optional: true

  validates_same_tenant :residential_property, :unit, :visit, :visit_participant, :visitor_profile,
                        :vehicle, :recorded_by_person, :staff_shift
end
