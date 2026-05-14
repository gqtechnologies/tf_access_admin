# frozen_string_literal: true

# == Schema Information
#
# Table name: parcel_deliveries
#
#  id                      :uuid             not null, primary key
#  courier_company         :string
#  delivery_type           :string           default("parcel"), not null
#  metadata                :jsonb            not null
#  notes                   :text
#  notified_at             :datetime
#  received_at             :datetime         not null
#  status                  :string           default("received"), not null
#  tracking_code           :string
#  withdrawn_at            :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  organization_id         :uuid             not null
#  received_by_person_id   :uuid
#  recipient_person_id     :uuid
#  residential_property_id :uuid             not null
#  staff_shift_id          :uuid
#  unit_id                 :uuid             not null
#  withdrawn_by_person_id  :uuid
#
# Indexes
#
#  index_parcel_deliveries_on_metadata                            (metadata) USING gin
#  index_parcel_deliveries_on_org_property_status_received_at     (organization_id,residential_property_id,status,received_at)
#  index_parcel_deliveries_on_org_received_by_person              (organization_id,received_by_person_id)
#  index_parcel_deliveries_on_org_tracking_code                   (organization_id,tracking_code)
#  index_parcel_deliveries_on_org_unit_status_received_at         (organization_id,unit_id,status,received_at)
#  index_parcel_deliveries_on_org_withdrawn_by_person             (organization_id,withdrawn_by_person_id)
#  index_parcel_deliveries_on_organization_id                     (organization_id)
#  index_parcel_deliveries_on_organization_id_and_staff_shift_id  (organization_id,staff_shift_id)
#  index_parcel_deliveries_on_received_by_person_id               (received_by_person_id)
#  index_parcel_deliveries_on_recipient_person_id                 (recipient_person_id)
#  index_parcel_deliveries_on_residential_property_id             (residential_property_id)
#  index_parcel_deliveries_on_staff_shift_id                      (staff_shift_id)
#  index_parcel_deliveries_on_unit_id                             (unit_id)
#  index_parcel_deliveries_on_withdrawn_by_person_id              (withdrawn_by_person_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (received_by_person_id => people.id)
#  fk_rails_...  (recipient_person_id => people.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#  fk_rails_...  (staff_shift_id => staff_shifts.id)
#  fk_rails_...  (unit_id => units.id)
#  fk_rails_...  (withdrawn_by_person_id => people.id)
#
class ParcelDelivery < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :unit
  belongs_to :recipient_person, class_name: "Person", optional: true
  belongs_to :received_by_person, class_name: "Person", optional: true
  belongs_to :withdrawn_by_person, class_name: "Person", optional: true
  belongs_to :staff_shift, optional: true

  has_many :parcel_delivery_status_histories, dependent: :destroy
end
