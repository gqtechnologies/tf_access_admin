# frozen_string_literal: true

# == Schema Information
#
# Table name: common_areas
#
#  id                      :uuid             not null, primary key
#  area_type               :string           not null
#  capacity                :integer
#  deleted_at              :datetime
#  metadata                :jsonb            not null
#  name                    :string           not null
#  requires_approval       :boolean          default(TRUE), not null
#  status                  :string           default("active"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  organization_id         :uuid             not null
#  residential_property_id :uuid             not null
#
# Indexes
#
#  idx_on_organization_id_residential_property_id_stat_8348429f7a  (organization_id,residential_property_id,status)
#  index_common_areas_on_deleted_at                                (deleted_at)
#  index_common_areas_on_metadata                                  (metadata) USING gin
#  index_common_areas_on_organization_id                           (organization_id)
#  index_common_areas_on_residential_property_id                   (residential_property_id)
#  index_common_areas_unique_name_per_property_when_active         (organization_id,residential_property_id,name) UNIQUE WHERE (deleted_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#
class CommonArea < ApplicationRecord
  acts_as_paranoid
  include CommonAreaTypes
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property

  validates_same_tenant :residential_property

  validates :area_type, presence: true, inclusion: { in: CommonAreaTypes::ALL }

  has_many :common_area_reservations, dependent: :restrict_with_error
  has_many :incidents, dependent: :nullify
  has_many :common_area_rules, dependent: :destroy
end
