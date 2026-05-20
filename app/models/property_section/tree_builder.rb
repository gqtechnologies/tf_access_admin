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

  private

  def build_nodes(nodes)
    nodes.sort_by { |section| [ section.position || Float::INFINITY, section.name ] }.map do |section|
      children = @by_parent[section.id] || []
      {
        id: section.id,
        name: section.name,
        code: section.code,
        section_type: section.section_type,
        position: section.position,
        parent_id: section.parent_id,
        children: build_nodes(children)
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
