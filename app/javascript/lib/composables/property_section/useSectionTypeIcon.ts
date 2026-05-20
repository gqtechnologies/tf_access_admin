import type { Component } from 'vue'
import {
  Building2,
  Layers,
  Leaf,
  Car,
  Package,
  Store,
  Sparkles,
  DoorOpen,
  Box,
  type LucideIcon,
} from 'lucide-vue-next'

const SECTION_TYPE_ICONS: Record<string, LucideIcon> = {
  block: Building2,
  tower: Building2,
  floor: Layers,
  parking: Car,
  storage: Package,
  commercial: Store,
  amenities: Sparkles,
  entrance: DoorOpen,
  garden: Leaf,
  other: Box,
}

export function useSectionTypeIcon() {
  function iconFor(sectionType: string): Component {
    return SECTION_TYPE_ICONS[sectionType] ?? Box
  }

  return { iconFor }
}
