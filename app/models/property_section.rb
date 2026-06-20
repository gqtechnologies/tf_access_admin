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
  include NormalizableAttributes
  include AlphanumericHyphenCodeValidatable
  include TenantScopedAssociations
  include PropertySectionHierarchy

  acts_as_tenant :organization
  acts_as_paranoid

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :parent, class_name: "PropertySection", optional: true, inverse_of: :children
  has_many :children, class_name: "PropertySection", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :visits, dependent: :destroy

  validates :section_type, presence: true, inclusion: { in: SectionTypes::ALL }
  validates :name, presence: true
  validates :residential_property, presence: true
  validates_alphanumeric_hyphen_code :code

  validates_same_tenant :residential_property, :parent
  validate :parent_is_valid

  before_validation :normalize_optional_attributes
  before_validation :assign_default_position, on: :create
  trims_attributes :name, :code

  def self.ransackable_attributes(_auth_object = nil)
    %w[name code section_type position residential_property_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[residential_property parent]
  end

  private

  def normalize_optional_attributes
    self.code = code.presence
    self.parent_id = parent_id.presence
  end

  def assign_default_position
    return if position.present?

    siblings = self.class.where(
      residential_property_id: residential_property_id,
      parent_id: parent_id
    )
    siblings = siblings.where.not(id: id) if persisted?
    self.position = (siblings.maximum(:position) || 0) + 1
  end

  def parent_is_valid
    return if parent_id.blank?

    if id.present? && parent_id == id
      errors.add(:parent_id, I18n.t("frontend.admin.property_sections.validations.parent_invalid"))
      return
    end

    if parent.nil?
      errors.add(:parent_id, I18n.t("frontend.admin.property_sections.validations.parent_invalid"))
      return
    end

    unless parent.residential_property_id == residential_property_id
      errors.add(:parent_id, I18n.t("frontend.admin.property_sections.validations.parent_same_property"))
      return
    end

    return unless id.present?

    if descendant_ids.include?(parent_id)
      errors.add(:parent_id, I18n.t("frontend.admin.property_sections.validations.parent_circular"))
    end
  end

  def descendant_ids
    ids = []
    queue = children.to_a
    while queue.any?
      child = queue.shift
      ids << child.id
      queue.concat(child.children.to_a)
    end
    ids
  end
end
