export type UnitOwnershipStats = {
  active_owners_count: number
  assigned_percentage: number | string
  available_percentage: number | string
  historical_owners_count: number
  total_owners_count: number
}

export type UnitOwnership = {
  id: string
  ownership_percentage: number | string
  starts_at: string
  ends_at: string | null
  status: string
  validity_state: 'current' | 'finished' | 'pending' | 'inactive'
  person_id: string
  person_display_name: string
  person_document_type: string | null
  person_document_number: string | null
  person_email: string | null
}

export type UnitOwnershipsPagination = {
  current_page: number
  per_page: number
  total_pages: number
  total_count: number
}

export type UnitOccupancyStats = {
  active_occupants_count: number
  active_authorizers_count: number
  historical_occupants_count: number
  total_occupants_count: number
}

export type UnitOccupancy = {
  id: string
  occupancy_type: string
  occupancy_type_label: string
  can_authorize_visits: boolean
  starts_at: string
  ends_at: string | null
  status: string
  status_label: string
  validity_state: 'current' | 'finished' | 'pending' | 'inactive'
  person_id: string
  person_display_name: string
  person_document_type: string | null
  person_document_number: string | null
  person_email: string | null
}

export type UnitOccupanciesPagination = UnitOwnershipsPagination

export type OccupancyTypeOption = {
  value: string
  label: string
}

export type UnitOccupancyPermissions = {
  create: boolean
  update: boolean
  destroy: boolean
}

export type UnitChangeHistoryEntry = {
  id: string
  occurred_at: string
  description: string
  actor_name: string
  tone: 'success' | 'warning' | 'neutral'
}

export type UnitDetail = {
  id: string
  identifier: string
  display_name: string | null
  title: string
  unit_type: string
  status: string
  area_m2: number | null
  residential_property_id: string
  residential_property_name: string
  property_section_id: string | null
  location_path: string[]
  ownership_stats: UnitOwnershipStats
  occupancy_stats: UnitOccupancyStats
}
