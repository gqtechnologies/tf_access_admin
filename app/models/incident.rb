# frozen_string_literal: true

# == Schema Information
#
# Table name: incidents
#
#  id                      :uuid             not null, primary key
#  category                :string           not null
#  deleted_at              :datetime
#  description             :text             not null
#  metadata                :jsonb            not null
#  occurred_at             :datetime
#  priority                :string           default("normal"), not null
#  resolution              :text
#  resolved_at             :datetime
#  status                  :string           default("open"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  assigned_to_person_id   :uuid
#  common_area_id          :uuid
#  organization_id         :uuid             not null
#  parcel_delivery_id      :uuid
#  reported_by_person_id   :uuid
#  residential_property_id :uuid             not null
#  unit_id                 :uuid
#  vehicle_id              :uuid
#  visit_id                :uuid
#
# Indexes
#
#  index_incidents_on_assigned_to_person_id                        (assigned_to_person_id)
#  index_incidents_on_common_area_id                               (common_area_id)
#  index_incidents_on_deleted_at                                   (deleted_at)
#  index_incidents_on_metadata                                     (metadata) USING gin
#  index_incidents_on_org_assigned_person_status                   (organization_id,assigned_to_person_id,status)
#  index_incidents_on_org_property_status_priority_occurred        (organization_id,residential_property_id,status,priority,occurred_at)
#  index_incidents_on_org_reported_by_person                       (organization_id,reported_by_person_id)
#  index_incidents_on_organization_id                              (organization_id)
#  index_incidents_on_organization_id_and_unit_id_and_occurred_at  (organization_id,unit_id,occurred_at)
#  index_incidents_on_parcel_delivery_id                           (parcel_delivery_id)
#  index_incidents_on_reported_by_person_id                        (reported_by_person_id)
#  index_incidents_on_residential_property_id                      (residential_property_id)
#  index_incidents_on_unit_id                                      (unit_id)
#  index_incidents_on_vehicle_id                                   (vehicle_id)
#  index_incidents_on_visit_id                                     (visit_id)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_to_person_id => people.id)
#  fk_rails_...  (common_area_id => common_areas.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (parcel_delivery_id => parcel_deliveries.id)
#  fk_rails_...  (reported_by_person_id => people.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#  fk_rails_...  (unit_id => units.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#  fk_rails_...  (visit_id => visits.id)
#
class Incident < ApplicationRecord
  acts_as_paranoid
  include IncidentCategories
  include Priorities
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :unit, optional: true
  belongs_to :common_area, optional: true
  belongs_to :visit, optional: true
  belongs_to :parcel_delivery, optional: true
  belongs_to :vehicle, optional: true
  belongs_to :reported_by_person, class_name: "Person", optional: true
  belongs_to :assigned_to_person, class_name: "Person", optional: true

  validates_same_tenant :residential_property, :unit, :common_area, :visit, :parcel_delivery, :vehicle,
                        :reported_by_person, :assigned_to_person

  validates :category, presence: true, inclusion: { in: IncidentCategories::ALL }
  validates :priority, presence: true, inclusion: { in: Priorities::ALL }

  has_many :incident_status_histories, dependent: :destroy
end
