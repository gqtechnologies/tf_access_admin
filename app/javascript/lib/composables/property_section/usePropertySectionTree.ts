import { computed, ref, type Ref } from 'vue'
import type {
  PropertySectionParentOption,
  PropertySectionTreeNode,
} from '@/types/property_section'

export function usePropertySectionTree(
  tree: Ref<PropertySectionTreeNode[]>,
  searchQuery: Ref<string>,
) {
  const filteredTree = computed(() => {
    const query = searchQuery.value.trim().toLowerCase()
    if (!query) return tree.value
    return filterTree(tree.value, query)
  })

  const hasSections = computed(() => tree.value.length > 0)

  function findNodeById(
    nodes: PropertySectionTreeNode[],
    id: string,
  ): PropertySectionTreeNode | undefined {
    for (const node of nodes) {
      if (node.id === id) return node
      const found = findNodeById(node.children, id)
      if (found) return found
    }
    return undefined
  }

  function findAncestorIds(
    nodes: PropertySectionTreeNode[],
    targetId: string,
    ancestors: string[] = [],
  ): string[] | null {
    for (const node of nodes) {
      if (node.id === targetId) return ancestors
      const found = findAncestorIds(node.children, targetId, [...ancestors, node.id])
      if (found) return found
    }
    return null
  }

  return {
    filteredTree,
    hasSections,
    findNodeById,
    findAncestorIds,
  }
}

/** Local UI state for the structure page: search, selection and expansion (§8.3). */
export function usePropertySectionStructureState(tree: Ref<PropertySectionTreeNode[]>) {
  const search = ref('')
  const selectedId = ref<string | null>(null)
  const expandedIds = ref<Set<string>>(new Set())

  const { filteredTree, hasSections, findNodeById, findAncestorIds } = usePropertySectionTree(
    tree,
    search,
  )

  const selectedNode = computed(() => {
    if (!selectedId.value) return null
    return findNodeById(tree.value, selectedId.value) ?? null
  })

  const forceExpanded = computed(() => search.value.trim().length > 0)

  function selectNode(node: PropertySectionTreeNode) {
    selectedId.value = node.id
    expandAncestors(node.id)
  }

  function clearSelection() {
    selectedId.value = null
  }

  function expandAncestors(nodeId: string) {
    const ancestors = findAncestorIds(tree.value, nodeId) ?? []
    const next = new Set(expandedIds.value)
    ancestors.forEach((id) => next.add(id))
    expandedIds.value = next
  }

  function isExpanded(nodeId: string) {
    return forceExpanded.value || expandedIds.value.has(nodeId)
  }

  function setExpanded(nodeId: string, open: boolean) {
    const next = new Set(expandedIds.value)
    if (open) {
      next.add(nodeId)
    } else {
      next.delete(nodeId)
    }
    expandedIds.value = next
  }

  return {
    search,
    selectedId,
    selectedNode,
    filteredTree,
    hasSections,
    findNodeById,
    forceExpanded,
    selectNode,
    clearSelection,
    isExpanded,
    setExpanded,
    expandAncestors,
  }
}

export function buildSectionPreviewPath(
  propertyName: string,
  placement: 'root' | 'child',
  parentId: string | undefined,
  sectionName: string,
  parentOptions: PropertySectionParentOption[],
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

function unitMatchesQuery(
  unit: PropertySectionTreeNode['units'][number],
  query: string,
): boolean {
  return (
    unit.identifier.toLowerCase().includes(query) ||
    (unit.display_name?.toLowerCase().includes(query) ?? false)
  )
}

function filterTree(
  nodes: PropertySectionTreeNode[],
  query: string,
): PropertySectionTreeNode[] {
  return nodes
    .map((node) => {
      const children = filterTree(node.children, query)
      const units = (node.units ?? []).filter((unit) => unitMatchesQuery(unit, query))
      const matches =
        node.name.toLowerCase().includes(query) ||
        (node.code?.toLowerCase().includes(query) ?? false)

      if (matches || children.length > 0 || units.length > 0) {
        return {
          ...node,
          children: matches ? node.children : children,
          units: matches ? node.units : units,
        }
      }
      return null
    })
    .filter((node): node is PropertySectionTreeNode => node !== null)
}

/** Maximum hierarchy depth enforced by the domain (root + subsection). */
export const PROPERTY_SECTION_MAX_DEPTH = 2

export function nodeHasChildren(node: PropertySectionTreeNode) {
  return node.children.length > 0
}

/** Roots with subsections cannot be nested under another root (§8.6). */
export function canMoveUnderParent(
  node: PropertySectionTreeNode,
  parentId: string | null | undefined,
) {
  if (!parentId) return true
  if (node.depth !== 1) return true
  return !nodeHasChildren(node)
}
