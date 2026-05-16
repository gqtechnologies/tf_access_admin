# frozen_string_literal: true

# == Schema Information
#
# Table name: property_setting_versions
#
#  id                      :uuid             not null, primary key
#  change_reason           :text
#  snapshot                :jsonb            not null
#  version_number          :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  changed_by_person_id    :uuid
#  organization_id         :uuid             not null
#  property_setting_id     :uuid             not null
#  residential_property_id :uuid             not null
#
# Indexes
#
#  idx_property_setting_versions_on_org_and_setting            (organization_id,property_setting_id)
#  idx_property_setting_versions_on_org_property_version       (organization_id,residential_property_id,version_number)
#  index_property_setting_versions_on_changed_by_person_id     (changed_by_person_id)
#  index_property_setting_versions_on_organization_id          (organization_id)
#  index_property_setting_versions_on_property_setting_id      (property_setting_id)
#  index_property_setting_versions_on_residential_property_id  (residential_property_id)
#  index_property_setting_versions_on_snapshot                 (snapshot) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (changed_by_person_id => people.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (property_setting_id => property_settings.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#
class PropertySettingVersion < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :property_setting
  belongs_to :changed_by_person, class_name: "Person", optional: true

  validates :version_number, presence: true

  validates_same_tenant :residential_property, :property_setting, :changed_by_person
end
