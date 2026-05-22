import type { PropertySectionTreeNode } from '@/types/property_section'

/**
 * Builds breadcrumb segments from property root to the target section.
 */
export function buildSectionBreadcrumbPath(
  tree: PropertySectionTreeNode[],
  sectionId: string,
  propertyName: string
): string[] {
  const sectionPath = findSectionPath(tree, sectionId)
  if (!sectionPath) return [propertyName]

  return [propertyName, ...sectionPath]
}

function findSectionPath(
  nodes: PropertySectionTreeNode[],
  sectionId: string,
  trail: string[] = []
): string[] | null {
  for (const node of nodes) {
    const nextTrail = [...trail, node.name]

    if (node.id === sectionId) return nextTrail

    const found = findSectionPath(node.children, sectionId, nextTrail)
    if (found) return found
  }

  return null
}
