# frozen_string_literal: true

class PropertySection::BreadcrumbPath
  def self.build(section, sections_by_id:)
    return [] unless section

    path = []
    current = section
    visited = Set.new

    while current
      break if visited.include?(current.id)

      visited.add(current.id)
      path.unshift(current.name)
      current = current.parent_id ? sections_by_id[current.parent_id] : nil
    end

    path
  end
end
