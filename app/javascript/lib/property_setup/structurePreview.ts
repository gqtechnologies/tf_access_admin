export type QuickStructureParams = {
  towers: number
  floors_per_tower: number
  units_per_floor: number
  tower_prefix: string
  floor_prefix: string
}

export type StructureFormatLevel = {
  section_type: string
  label_key: string
  suffix_type: 'letter' | 'number'
}

export type PropertyStructureFormat = {
  levels: StructureFormatLevel[]
  units_in: string
}

export type StructureTreeNode = {
  id: string
  name: string
  position?: number
  children?: StructureTreeNode[]
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

export function buildQuickStructureTree(params: QuickStructureParams): StructureTreeNode[] {
  const towers = Math.max(params.towers, 0)
  const floorsPerTower = Math.max(params.floors_per_tower, 0)

  return Array.from({ length: towers }, (_, towerIndex) => {
    const towerLabel = String.fromCharCode(65 + towerIndex)
    const children = Array.from({ length: floorsPerTower }, (_, floorIndex) => ({
      id: `tower-${towerIndex}-floor-${floorIndex + 1}`,
      name: `${params.floor_prefix} ${floorIndex + 1}`,
    }))

    return {
      id: `tower-${towerIndex}`,
      name: `${params.tower_prefix} ${towerLabel}`,
      children,
    }
  })
}

export function quickStructureCounts(params: QuickStructureParams) {
  const towers = Math.max(params.towers, 0)
  const floors = towers * Math.max(params.floors_per_tower, 0)
  const estimatedUnits = floors * Math.max(params.units_per_floor, 0)

  return { towers, floors, estimated_units: estimatedUnits, sections: towers + floors }
}
