# frozen_string_literal: true

module PropertySections
  # Draft-phase soft delete of a section (wizard-manual-structure-builder).
  #
  # Unlike {Archive} (which only flips status and keeps the node in the tree),
  # +Destroy+ removes the section from the default scope via paranoia
  # (+acts_as_paranoid+, +section.destroy+) so a mistaken section disappears from
  # the live builder preview. It is only valid while the property is still in
  # +draft+ status. Children/units are +dependent: :restrict_with_error+, so a
  # section with dependents fails cleanly and the error is surfaced. Idempotent
  # when the section is already soft-deleted.
  class Destroy < Base
    def initialize(actor:, section:)
      super(actor: actor)
      @section = section
    end

    def call
      authorize_manage_sections!(@section.residential_property)

      return Result.noop(@section) if @section.deleted_at.present?
      return Result.invalid(@section) unless draft_property?

      @section.with_lock do
        return Result.invalid(@section) unless @section.destroy
      end

      Result.success(@section)
    end

    private

    def draft_property?
      return true if @section.residential_property&.status == PropertyStatuses::DRAFT

      @section.errors.add(:base, :property_not_draft)
      false
    end
  end
end
