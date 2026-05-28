export type PropertySectionUnitTreeNode = {
  id: string
  identifier: string
  display_name: string | null
  unit_type: string
}

export type PropertySectionTreeNode = {
  id: string
  name: string
  code: string | null
  section_type: string
  position: number | null
  parent_id: string | null
  children: PropertySectionTreeNode[]
  units: PropertySectionUnitTreeNode[]
}

export type PropertySection = {
  id?: string
  name: string
  code: string | null
  section_type: string
  position: number | null
  residential_property_id: string
  residential_property_name?: string | null
  parent_id: string | null
  parent_name?: string | null
  metadata?: Record<string, unknown>
  organization_id?: string
  created_at?: string
  updated_at?: string
}

export type PropertySectionParentOption = {
  id: string
  name: string
  section_type: string
  depth: number
}
