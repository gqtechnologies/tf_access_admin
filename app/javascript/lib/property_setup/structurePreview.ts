export type StructureFormatLevel = {
  section_type: string
  label_key: string
  suffix_type: 'letter' | 'number'
}

export type PropertyStructureFormat = {
  levels: StructureFormatLevel[]
  units_in: string
}

/** Generic quick-structure params emitted by the dynamic form, sent to the
 * format-aware backend preview/commit. */
export type QuickStructureFormParams = {
  level_1_count: number
  level_2_count: number
  level_1_prefix: string
  level_2_prefix: string
  skip_top_level: boolean
}

/** Flat node returned by the backend structure_preview endpoint. */
export type PreviewNode = {
  id: string
  parent_id?: string
  name: string
  section_type: string
  depth: number
}

export type StructureTreeNode = {
  id: string
  name: string
  position?: number
  children?: StructureTreeNode[]
  /** Projected unit identifiers injected into leaf nodes for step 3 preview. */
  units?: string[]
}

export type TreeChildDisplayItem =
  | { kind: 'child'; node: StructureTreeNode }
  | { kind: 'ellipsis' }

export function displayTreeChildren(children: StructureTreeNode[] = []): TreeChildDisplayItem[] {
  if (children.length <= 4) {
    return children.map((node) => ({ kind: 'child', node }))
  }

  return [
    { kind: 'child', node: children[0] },
    { kind: 'child', node: children[1] },
    { kind: 'ellipsis' },
    { kind: 'child', node: children[children.length - 1] },
  ]
}

/** Builds a nested tree from the flat preview nodes returned by the backend. */
export function buildTreeFromPreviewNodes(nodes: PreviewNode[]): StructureTreeNode[] {
  const byId = new Map<string, StructureTreeNode>()
  const roots: StructureTreeNode[] = []

  for (const node of nodes) {
    byId.set(node.id, { id: node.id, name: node.name, children: [] })
  }

  for (const node of nodes) {
    const current = byId.get(node.id)!
    const parent = node.parent_id ? byId.get(node.parent_id) : undefined
    if (parent) {
      parent.children!.push(current)
    } else {
      roots.push(current)
    }
  }

  return roots
}
