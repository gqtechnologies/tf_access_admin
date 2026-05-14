# frozen_string_literal: true

# == Schema Information
#
# Table name: units
#
#  id                      :uuid             not null, primary key
#  area_m2                 :decimal(10, 2)
#  deleted_at              :datetime
#  display_name            :string
#  identifier              :string           not null
#  metadata                :jsonb            not null
#  normalized_identifier   :string           not null
#  status                  :string           default("active"), not null
#  unit_type               :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  organization_id         :uuid             not null
#  property_section_id     :uuid
#  residential_property_id :uuid             not null
#
# Indexes
#
#  idx_on_organization_id_residential_property_id_stat_47cefd6e3a  (organization_id,residential_property_id,status)
#  idx_units_unique_normalized_id_per_context                      (organization_id,residential_property_id,property_section_id,normalized_identifier) UNIQUE WHERE (deleted_at IS NULL)
#  index_units_on_deleted_at                                       (deleted_at)
#  index_units_on_metadata                                         (metadata) USING gin
#  index_units_on_organization_id                                  (organization_id)
#  index_units_on_organization_id_and_property_section_id          (organization_id,property_section_id)
#  index_units_on_property_section_id                              (property_section_id)
#  index_units_on_residential_property_id                          (residential_property_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (property_section_id => property_sections.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#
class Unit < ApplicationRecord
  acts_as_tenant :organization
  acts_as_paranoid

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :property_section, optional: true

  has_many :unit_ownerships, dependent: :destroy
  has_many :lease_contracts, dependent: :destroy
  has_many :unit_occupancies, dependent: :destroy
  has_many :authorized_residents, dependent: :destroy

  validates :unit_type, presence: true
  validates :identifier, presence: true
  validates :normalized_identifier, presence: true
  validates :status, presence: true
end
