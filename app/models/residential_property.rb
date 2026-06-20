# frozen_string_literal: true

# == Schema Information
#
# Table name: residential_properties
#
#  id              :uuid             not null, primary key
#  address_line    :string
#  city            :string
#  code            :string
#  country         :string           default("Chile"), not null
#  deleted_at      :datetime
#  metadata        :jsonb            not null
#  name            :string           not null
#  property_type   :string           not null
#  region          :string
#  status          :string           default("active"), not null
#  timezone        :string           default("America/Santiago"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :uuid             not null
#
# Indexes
#
#  idx_on_organization_id_property_type_d2e2ee8ca6             (organization_id,property_type)
#  idx_residential_properties_unique_code_per_org              (organization_id,code) UNIQUE WHERE ((code IS NOT NULL) AND (deleted_at IS NULL))
#  index_residential_properties_on_deleted_at                  (deleted_at)
#  index_residential_properties_on_metadata                    (metadata) USING gin
#  index_residential_properties_on_organization_id             (organization_id)
#  index_residential_properties_on_organization_id_and_status  (organization_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#
class ResidentialProperty < ApplicationRecord
  include PropertyTypes
  include NormalizableAttributes

  acts_as_tenant :organization
  acts_as_paranoid

  belongs_to :organization
  has_many :property_sections, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_one :property_setting, dependent: :destroy

  validates :name, presence: true
  validates :property_type, presence: true, inclusion: { in: PropertyTypes::ALL }
  validates :status, presence: true

  before_validation :normalize_optional_strings
  trims_attributes :name, :code, :address_line, :city, :region, :country, :timezone

  def self.ransackable_attributes(_auth_object = nil)
    %w[name code city region address_line status property_type]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  private

  def normalize_optional_strings
    self.code = code.presence
    self.address_line = address_line.presence
    self.city = city.presence
    self.region = region.presence
  end
end
