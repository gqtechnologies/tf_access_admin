# frozen_string_literal: true

# == Schema Information
#
# Table name: common_area_reservations
#
#  id                      :uuid             not null, primary key
#  approved_at             :datetime
#  ends_at                 :datetime         not null
#  guest_count             :integer          default(0)
#  metadata                :jsonb            not null
#  rejection_reason        :text
#  starts_at               :datetime         not null
#  status                  :string           default("pending"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  approved_by_person_id   :uuid
#  common_area_id          :uuid             not null
#  organization_id         :uuid             not null
#  requested_by_person_id  :uuid             not null
#  residential_property_id :uuid             not null
#  unit_id                 :uuid             not null
#
# Indexes
#
#  common_area_reservations_no_overlap                           (organization_id, common_area_id, tsrange(starts_at, ends_at, '[)'::text)) WHERE ((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('approved'::character varying)::text])) USING gist
#  idx_on_organization_id_unit_id_status_00945a979c              (organization_id,unit_id,status)
#  index_common_area_reservations_on_approved_by_person_id       (approved_by_person_id)
#  index_common_area_reservations_on_common_area_id              (common_area_id)
#  index_common_area_reservations_on_metadata                    (metadata) USING gin
#  index_common_area_reservations_on_org_approved_by_person      (organization_id,approved_by_person_id)
#  index_common_area_reservations_on_org_area_time_range         (organization_id,common_area_id,starts_at,ends_at)
#  index_common_area_reservations_on_org_requester_status        (organization_id,requested_by_person_id,status)
#  index_common_area_reservations_on_organization_id             (organization_id)
#  index_common_area_reservations_on_organization_id_and_status  (organization_id,status)
#  index_common_area_reservations_on_requested_by_person_id      (requested_by_person_id)
#  index_common_area_reservations_on_residential_property_id     (residential_property_id)
#  index_common_area_reservations_on_unit_id                     (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_person_id => people.id)
#  fk_rails_...  (common_area_id => common_areas.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (requested_by_person_id => people.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#  fk_rails_...  (unit_id => units.id)
#
class CommonAreaReservation < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :common_area
  belongs_to :residential_property
  belongs_to :unit
  belongs_to :requested_by_person, class_name: "Person"
  belongs_to :approved_by_person, class_name: "Person", optional: true

  validates_same_tenant :common_area, :residential_property, :unit, :requested_by_person, :approved_by_person

  has_many :common_area_reservation_status_histories, dependent: :destroy
end
