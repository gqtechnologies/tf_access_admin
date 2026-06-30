# frozen_string_literal: true

module PropertySections
  # Creates N sections under a single context (N roots, or N children of one root)
  # in one transaction, reusing {PropertySections::Create} per node so every
  # +PropertySectionHierarchy+ rule and the two-level limit still apply
  # (wizard-manual-structure-builder).
  #
  # Names come from {Properties::Setup::SectionNameSequence}: either an explicit
  # +names+ list (individual mode) or generated from +prefix+/+suffix_type+/+count+
  # (multiple mode). Because each node goes through +Create+, a child batch under a
  # non-root parent is rejected by the hierarchy validation; any single failure
  # rolls back the whole batch and returns the failing node with its errors.
  class CreateBatch < Base
    def initialize(actor:, property:, parent: nil, section_type:, names: nil,
                   prefix: nil, suffix_type: :letter, count: nil, code: nil)
      super(actor: actor)
      @property = property
      @parent = parent
      @section_type = section_type
      @names = names
      @prefix = prefix
      @suffix_type = suffix_type
      @count = count
      @code = code
    end

    def call
      authorize_manage_sections!(@property)

      names = resolved_names
      return BatchResult.invalid(blank_batch_section) if names.empty?

      created = []
      ActiveRecord::Base.transaction do
        names.each_with_index do |name, index|
          result = PropertySections::Create.call(
            actor: actor,
            property: @property,
            parent: @parent,
            attributes: node_attributes(name, single: names.one?)
          )

          unless result.success?
            @failed_section = result.section
            raise ActiveRecord::Rollback
          end

          created << result.section
        end
      end

      return BatchResult.invalid(@failed_section) if @failed_section

      BatchResult.success(created)
    end

    private

    def resolved_names
      return Array(@names).map(&:to_s).reject(&:blank?) if @names.present?
      return [] if @prefix.blank? || @count.to_i <= 0

      Properties::Setup::SectionNameSequence.names(
        prefix: @prefix, suffix_type: @suffix_type, count: @count
      )
    end

    # A single internal code only applies when creating exactly one section, to
    # avoid duplicate-code collisions across a generated batch.
    def node_attributes(name, single:)
      attrs = { name: name, section_type: @section_type }
      attrs[:code] = @code if single && @code.present?
      attrs
    end

    def blank_batch_section
      section = PropertySection.new(section_type: @section_type)
      assign_organization_from_property!(section, @property)
      section.errors.add(:base, :empty_batch)
      section
    end
  end
end
