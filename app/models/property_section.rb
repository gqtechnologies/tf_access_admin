# frozen_string_literal: true

# == Schema Information
#
# Table name: property_sections
#
#  id                      :uuid             not null, primary key
#  code                    :string
#  deleted_at              :datetime
#  metadata                :jsonb            not null
#  name                    :string           not null
#  position                :integer
#  section_type            :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  organization_id         :uuid             not null
#  parent_id               :uuid
#  residential_property_id :uuid             not null
#
# Indexes
#
#  idx_property_sections_on_org_property_parent        (organization_id,residential_property_id,parent_id)
#  idx_property_sections_unique_code_in_context        (organization_id,residential_property_id,parent_id,section_type,code) UNIQUE WHERE ((code IS NOT NULL) AND (deleted_at IS NULL))
#  index_property_sections_on_deleted_at               (deleted_at)
#  index_property_sections_on_metadata                 (metadata) USING gin
#  index_property_sections_on_organization_id          (organization_id)
#  index_property_sections_on_parent_id                (parent_id)
#  index_property_sections_on_residential_property_id  (residential_property_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (parent_id => property_sections.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#
class PropertySection < ApplicationRecord
  include SectionTypes
  include TenantScopedAssociations

  acts_as_tenant :organization
  acts_as_paranoid

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :parent, class_name: "PropertySection", optional: true, inverse_of: :children
  has_many :children, class_name: "PropertySection", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :units, dependent: :destroy

  validates :section_type, presence: true, inclusion: { in: SectionTypes::ALL }
  validates :name, presence: true

  validates_same_tenant :residential_property, :parent
end
