import { computed, type Ref } from 'vue'
import type {
  PropertySectionParentOption,
  PropertySectionTreeNode,
} from '@/types/property_section'

export function usePropertySectionTree(
  tree: Ref<PropertySectionTreeNode[]>,
  searchQuery: Ref<string>
) {
  const filteredTree = computed(() => {
    const query = searchQuery.value.trim().toLowerCase()
    if (!query) return tree.value
    return filterTree(tree.value, query)
  })

  const hasSections = computed(() => tree.value.length > 0)

  function findNodeById(
    nodes: PropertySectionTreeNode[],
    id: string
  ): PropertySectionTreeNode | undefined {
    for (const node of nodes) {
      if (node.id === id) return node
      const found = findNodeById(node.children, id)
      if (found) return found
    }
    return undefined
  }

  return {
    filteredTree,
    hasSections,
    findNodeById,
  }
}

export function buildSectionPreviewPath(
  propertyName: string,
  placement: 'root' | 'child',
  parentId: string | undefined,
  sectionName: string,
  parentOptions: PropertySectionParentOption[]
): string {
  const name = sectionName.trim() || '…'
  if (placement === 'root') {
    return `${propertyName} > ${name}`
  }

  const parent = parentOptions.find((option) => option.id === parentId)
  if (!parent) {
    return `${propertyName} > ${name}`
  }

  return `${propertyName} > ${parent.name} > ${name}`
}

function filterTree(
  nodes: PropertySectionTreeNode[],
  query: string
): PropertySectionTreeNode[] {
  return nodes
    .map((node) => {
      const children = filterTree(node.children, query)
      const matches =
        node.name.toLowerCase().includes(query) ||
        (node.code?.toLowerCase().includes(query) ?? false)

      if (matches || children.length > 0) {
        return { ...node, children }
      }
      return null
    })
    .filter((node): node is PropertySectionTreeNode => node !== null)
}
