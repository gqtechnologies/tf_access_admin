import type { StructureTreeNode } from '@/lib/property_setup/structurePreview'

export type UnitsPreviewParams = {
  unit_type?: string
  identifier_format?: string
  quantity_per_floor?: number
}

export type UnitsPreviewGroup = {
  label: string
  identifiers: string
}

function floorBase(floor: StructureTreeNode, format: string): number {
  if (format !== 'floor_sequential') return 1

  if (typeof floor.position === 'number' && floor.position > 0) {
    return floor.position * 100
  }

  const match = floor.name.match(/(\d+)\s*$/)
  return (match ? Number.parseInt(match[1], 10) : 1) * 100
}

function identifiersForFloor(floor: StructureTreeNode, params: UnitsPreviewParams): string {
  const quantity = Math.max(params.quantity_per_floor ?? 4, 1)
  const format = params.identifier_format ?? 'floor_sequential'
  const base = floorBase(floor, format)

  return Array.from({ length: quantity }, (_, index) => {
    if (format === 'floor_sequential') return String(base + index + 1)
    return String(index + 1)
  }).join(', ')
}

export function buildUnitsPreviewFromTree(
  tree: StructureTreeNode[],
  params: UnitsPreviewParams,
): UnitsPreviewGroup[] {
  const groups: UnitsPreviewGroup[] = []

  for (const tower of tree) {
    const floors = tower.children ?? []
    if (floors.length > 0) {
      for (const floor of floors) {
        groups.push({
          label: `${tower.name} - ${floor.name}`,
          identifiers: identifiersForFloor(floor, params),
        })
      }
      continue
    }

    groups.push({
      label: tower.name,
      identifiers: identifiersForFloor(tower, params),
    })
  }

  return groups
}

export function countUnitsPreviewGroups(groups: UnitsPreviewGroup[]): number {
  return groups.reduce((total, group) => {
    if (!group.identifiers) return total
    return total + group.identifiers.split(',').map((part) => part.trim()).filter(Boolean).length
  }, 0)
}
