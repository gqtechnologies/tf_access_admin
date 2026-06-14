# frozen_string_literal: true

# Enforces a two-level section tree:
# - Root sections (no parent) may have child sections.
# - Child sections (with a parent) may only have units, not more child sections.
module PropertySectionHierarchy
  extend ActiveSupport::Concern

  included do
    validate :parent_must_be_root_section
    validate :section_with_children_cannot_be_nested
    validate :parent_cannot_have_units
    validate :container_cannot_have_units
  end

  def root_section?
    parent_id.blank?
  end

  def child_section?
    parent_id.present?
  end

  def accepts_child_sections?
    root_section?
  end

  def accepts_units?
    children.none?
  end

  private

  def parent_must_be_root_section
    return if parent_id.blank?

    if parent.nil?
      errors.add(:parent_id, I18n.t("frontend.admin.property_sections.validations.parent_invalid"))
      return
    end

    return if parent.root_section?

    errors.add(:parent_id, I18n.t("frontend.admin.property_sections.validations.parent_must_be_root"))
  end

  def section_with_children_cannot_be_nested
    return if parent_id.blank?
    return unless children.exists?

    errors.add(:parent_id, I18n.t("frontend.admin.property_sections.validations.cannot_nest_with_children"))
  end

  def parent_cannot_have_units
    return if parent_id.blank?
    return unless parent&.units&.exists?

    errors.add(:parent_id, I18n.t("frontend.admin.property_sections.validations.parent_has_units"))
  end

  def container_cannot_have_units
    return unless units.exists?
    return if children.none?

    errors.add(:base, I18n.t("frontend.admin.property_sections.validations.container_cannot_have_units"))
  end
end
