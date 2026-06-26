# frozen_string_literal: true

module Properties
  module Setup
    # Builds paginated unit identifier previews from structure parameters.
    class GenerateUnitsPreview
      DEFAULT_PER_PAGE = 20

      def self.call(property:, params: {}, page: 1, per_page: DEFAULT_PER_PAGE)
        new(property: property, params: params, page: page, per_page: per_page).call
      end

      def initialize(property:, params:, page:, per_page:)
        @property = property
        @params = params.to_h.with_indifferent_access
        @page = [ page.to_i, 1 ].max
        @per_page = [ per_page.to_i, 1 ].max
      end

      def call
        rows = build_rows
        total = rows.size
        offset = (@page - 1) * @per_page
        page_rows = rows.slice(offset, @per_page) || []

        {
          rows: page_rows,
          total_units: total,
          pagination: {
            page: @page,
            per_page: @per_page,
            total: total,
            total_pages: (total.to_f / @per_page).ceil
          }
        }
      end

      private

      def build_rows
        quantity_per_floor = @params.fetch(:quantity_per_floor, 4).to_i
        format = @params.fetch(:identifier_format, "floor_sequential")

        floor_sections = @property.property_sections
          .where(section_type: SectionTypes::FLOOR)
          .includes(:parent)
          .order(:position, :name)

        if floor_sections.none?
          return build_flat_rows(quantity_per_floor, format)
        end

        floor_sections.flat_map do |floor|
          tower_name = floor.parent&.name
          base = format == "floor_sequential" ? ((floor.position || 1) * 100) : 1

          quantity_per_floor.times.map do |index|
            identifier = (base + index + 1).to_s
            {
              tower: tower_name,
              floor: floor.name,
              identifier: identifier
            }
          end
        end
      end

      def build_flat_rows(quantity_per_floor, format)
        estimated = WizardState.estimated_units(@property).to_i
        count = estimated.positive? ? estimated : quantity_per_floor

        count.times.map do |index|
          identifier = format == "floor_sequential" ? (101 + index).to_s : (index + 1).to_s
          { tower: nil, floor: nil, identifier: identifier }
        end
      end
    end
  end
end
