# frozen_string_literal: true

class PropertySection::TreeBuilder
  def initialize(sections)
    @sections = sections.to_a
    @by_parent = @sections.group_by(&:parent_id)
  end

  def as_json
    build_nodes(@by_parent[nil] || [])
  end

  def flat_with_depth
    flatten_nodes(build_nodes(@by_parent[nil] || []))
  end

  # Only root sections may be parents of another section (one nesting level).
  def root_parent_options
    flat_with_depth.select { |option| option[:depth].zero? }
  end

  private

  def build_nodes(nodes)
    nodes.sort_by { |section| [ section.position || Float::INFINITY, section.name ] }.map do |section|
      child_sections = @by_parent[section.id] || []
      children = build_nodes(child_sections)

      {
        id: section.id,
        name: section.name,
        code: section.code,
        section_type: section.section_type,
        position: section.position,
        parent_id: section.parent_id,
        children: children,
        units: build_units(section, child_sections)
      }
    end
  end

  def build_units(section, child_sections)
    return [] if child_sections.any?

    section.units.sort_by { |unit| [ unit.identifier.to_s.downcase, unit.id ] }.map do |unit|
      {
        id: unit.id,
        identifier: unit.identifier,
        display_name: unit.display_name,
        unit_type: unit.unit_type
      }
    end
  end

  def flatten_nodes(nodes, depth = 0)
    nodes.flat_map do |node|
      entry = {
        id: node[:id],
        name: node[:name],
        section_type: node[:section_type],
        depth: depth
      }
      [ entry ] + flatten_nodes(node[:children], depth + 1)
    end
  end
end
