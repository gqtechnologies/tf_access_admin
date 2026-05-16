# frozen_string_literal: true

# == Schema Information
#
# Table name: property_settings
#
#  id                                  :uuid             not null, primary key
#  active_notification_channels        :jsonb            not null
#  allow_recurring_visits              :boolean          default(FALSE), not null
#  concierge_can_approve_visits        :boolean          default(FALSE), not null
#  max_reservations_per_month          :integer
#  max_simultaneous_visitors_per_unit  :integer          default(5), not null
#  max_visitors_per_visit              :integer          default(5), not null
#  metadata                            :jsonb            not null
#  parcel_requires_signature           :boolean          default(FALSE), not null
#  reservation_max_duration_minutes    :integer
#  reservation_min_advance_hours       :integer          default(0), not null
#  reservation_requires_approval       :boolean          default(TRUE), not null
#  vehicle_plate_required              :boolean          default(FALSE), not null
#  visit_requires_concierge_validation :boolean          default(TRUE), not null
#  visit_requires_resident_approval    :boolean          default(TRUE), not null
#  visitor_identity_document_required  :boolean          default(FALSE), not null
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  organization_id                     :uuid             not null
#  residential_property_id             :uuid             not null
#
# Indexes
#
#  idx_on_organization_id_residential_property_id_ef39d448db  (organization_id,residential_property_id) UNIQUE
#  index_property_settings_on_active_notification_channels    (active_notification_channels) USING gin
#  index_property_settings_on_metadata                        (metadata) USING gin
#  index_property_settings_on_organization_id                 (organization_id)
#  index_property_settings_on_residential_property_id         (residential_property_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#
class PropertySetting < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property
  has_many :property_setting_versions, dependent: :destroy

  validates_same_tenant :residential_property
end
