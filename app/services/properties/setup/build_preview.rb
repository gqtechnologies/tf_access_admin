# frozen_string_literal: true

module Properties
  module Setup
    # Aggregates wizard summary data for review and confirmation steps.
    class BuildPreview
      def self.call(property:, actor: nil)
        new(property: property, actor: actor).call
      end

      def initialize(property:, actor: nil)
        @property = property
        @actor = actor
      end

      def call
        sections = @property.property_sections.includes(:parent)
        units = @property.units.includes(:property_section)
        wizard = WizardState.read(@property)

        {
          property: property_summary,
          structure: structure_summary(sections, wizard),
          units: units_summary(units),
          counts: {
            sections: sections.count,
            units: units.count,
            **structure_level_counts(sections)
          },
          blocking_errors: blocking_errors(units),
          warnings: warnings(wizard),
          duplicates: [],
          omitted: []
        }
      end

      private

      # fix-automatic-unit-generation §8: structure counts are resolved from the
      # property's recommended +PropertyStructureFormat+ (top level + +units_in+
      # leaf), not from hardcoded tower/floor section types, so condominium/sector
      # structures report accurate, non-zero counts.
      #
      # +level_2+ is only populated for two-level formats. For a single-level
      # format the sole level *is* the leaf (+levels.first == units_in+), so
      # counting +units_in+ again would double-count the same sections; +level_2+
      # stays 0. Mirrors +GenerateStructurePreview.counts+.
      def structure_level_counts(sections)
        format = StructureFormatResolver.for(property_type: @property.property_type)
        return { level_1: 0, level_2: 0 } if format.nil?

        top_type = format.levels.first[:section_type]
        {
          level_1: sections.where(section_type: top_type).count,
          level_2: format.single_level? ? 0 : sections.where(section_type: format.units_in).count
        }
      end

      def property_summary
        {
          name: @property.name,
          property_type: @property.property_type,
          address_line: @property.address_line,
          city: @property.city,
          region: @property.region,
          country: @property.country,
          estimated_units: WizardState.estimated_units(@property)
        }
      end

      def structure_summary(sections, wizard)
        {
          mode: wizard[:structure_mode],
          tree: PropertySections::TreeBuilder.new(
            actor: @actor,
            property: @property,
            include_units: false
          ).tree
        }
      rescue StandardError
        { mode: wizard[:structure_mode], tree: [] }
      end

      def units_summary(units)
        units.includes(property_section: :parent)
          .order(:identifier)
          .limit(4)
          .map { |unit| unit_preview_row(unit) }
      end

      def unit_preview_row(unit)
        section = unit.property_section
        tower = section&.parent

        {
          id: unit.id,
          code: unit.code,
          identifier: unit.identifier,
          unit_type: unit.unit_type,
          tower_name: tower&.name,
          floor_name: tower.present? ? section&.name : nil,
          section_name: section&.name,
          area_m2: unit.area_m2,
          orientation: unit.metadata["orientation"],
          bedrooms: unit.metadata["bedrooms"]
        }
      end

      def blocking_errors(units)
        errors = []
        if WizardState.structure_mode(@property) == "manual" && @property.property_sections.none?
          errors << I18n.t("frontend.admin.property_setup.step2.errors.manual_empty")
        end
        units_mode = WizardState.units_mode(@property)
        if units.none? && units_mode != "import" && units_mode != "automatic"
          errors << I18n.t("frontend.admin.property_setup.step3.errors.no_units")
        end
        errors
      end

      def warnings(_wizard)
        []
      end
    end
  end
end
