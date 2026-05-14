# frozen_string_literal: true

# == Schema Information
#
# Table name: parcel_delivery_status_histories
#
#  id                   :uuid             not null, primary key
#  from_status          :string
#  metadata             :jsonb            not null
#  reason               :text
#  to_status            :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  changed_by_person_id :uuid
#  organization_id      :uuid             not null
#  parcel_delivery_id   :uuid             not null
#
# Indexes
#
#  index_parcel_delivery_status_histories_on_changed_by_person_id  (changed_by_person_id)
#  index_parcel_delivery_status_histories_on_metadata              (metadata) USING gin
#  index_parcel_delivery_status_histories_on_org_changed_by        (organization_id,changed_by_person_id)
#  index_parcel_delivery_status_histories_on_org_delivery_created  (organization_id,parcel_delivery_id,created_at)
#  index_parcel_delivery_status_histories_on_organization_id       (organization_id)
#  index_parcel_delivery_status_histories_on_parcel_delivery_id    (parcel_delivery_id)
#
# Foreign Keys
#
#  fk_rails_...  (changed_by_person_id => people.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (parcel_delivery_id => parcel_deliveries.id)
#
class ParcelDeliveryStatusHistory < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :parcel_delivery
  belongs_to :changed_by_person, class_name: "Person", optional: true
end
