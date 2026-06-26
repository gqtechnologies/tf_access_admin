# frozen_string_literal: true

module Properties
  module Setup
    # Builds paginated preview nodes for quick structure generation.
    class GenerateStructurePreview
      DEFAULT_PER_PAGE = 20

      def self.call(params:, page: 1, per_page: DEFAULT_PER_PAGE)
        new(params: params, page: page, per_page: per_page).call
      end

      def initialize(params:, page:, per_page:)
        @params = params.to_h.with_indifferent_access
        @page = [ page.to_i, 1 ].max
        @per_page = [ per_page.to_i, 1 ].max
      end

      def call
        towers = @params.fetch(:towers, 1).to_i
        floors = @params.fetch(:floors_per_tower, 1).to_i
        tower_prefix = @params.fetch(:tower_prefix, "Torre").to_s
        floor_prefix = @params.fetch(:floor_prefix, "Piso").to_s

        nodes = []
        towers.times do |tower_index|
          tower_label = tower_letter(tower_index)
          tower_name = "#{tower_prefix} #{tower_label}"
          nodes << { id: "tower-#{tower_index}", name: tower_name, section_type: SectionTypes::TOWER, depth: 1 }

          floors.times do |floor_index|
            nodes << {
              id: "tower-#{tower_index}-floor-#{floor_index + 1}",
              parent_id: "tower-#{tower_index}",
              name: "#{floor_prefix} #{floor_index + 1}",
              section_type: SectionTypes::FLOOR,
              depth: 2
            }
          end
        end

        total = nodes.size
        offset = (@page - 1) * @per_page
        page_nodes = nodes.slice(offset, @per_page) || []

        {
          nodes: page_nodes,
          counts: {
            towers: towers,
            floors: towers * floors,
            estimated_units: towers * floors * @params.fetch(:units_per_floor, 0).to_i
          },
          pagination: {
            page: @page,
            per_page: @per_page,
            total: total,
            total_pages: (total.to_f / @per_page).ceil
          }
        }
      end

      private

      def tower_letter(index)
        ("A".ord + index).chr
      end
    end
  end
end
