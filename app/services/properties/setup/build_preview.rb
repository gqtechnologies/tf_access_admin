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
            towers: sections.where(section_type: SectionTypes::TOWER).count,
            floors: sections.where(section_type: SectionTypes::FLOOR).count
          },
          blocking_errors: blocking_errors(units),
          warnings: warnings(wizard),
          duplicates: [],
          omitted: []
        }
      end

      private

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
          code: unit.identifier,
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
