export type IncidentStatus = 'open' | 'in_progress' | 'resolved' | 'dismissed'
export type IncidentTab = 'open' | 'in_progress' | 'closed'

export type AdminIncident = {
  id: string
  category: string
  description: string
  priority: string
  status: IncidentStatus
  resolution: string | null
  created_at: string
  resolved_at: string | null
  unit: string | null
  common_area: string | null
  reported_by_name: string | null
  assigned_to_person_id: string | null
  assigned_to_name: string | null
}

export type IncidentAssignee = { id: string; name: string }
