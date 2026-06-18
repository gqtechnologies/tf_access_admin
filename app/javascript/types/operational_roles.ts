export type OperationalRoleKey = 'property_admin' | 'concierge' | 'cleaning_staff' | 'internal_staff'
export type OrgRoleKey = 'tenant_admin' | 'content_manager'
export type AnyRoleKey = OperationalRoleKey | OrgRoleKey

export interface OperationalRoleDefinition {
  key: OperationalRoleKey
  name: string
  description: string
  scope: 'property' | 'organization'
  users_count?: number
  capabilities?: string[]
}

export interface AssignmentRow {
  id: number
  person_id: number
  person_name: string | null
  role: string | null
  role_key: OperationalRoleKey | null
  staff_type: string
  residential_property_id: number
  property_name: string | null
  status: string
  starts_at: string | null
  ends_at: string | null
}

export interface CapabilityEntry {
  key: string
  label: string
  granted?: boolean
  roles?: Record<string, boolean>
}

export interface CapabilityModuleGroup {
  module: string
  capabilities: CapabilityEntry[]
}

export interface RoleSummary {
  defined_roles_count: number
  total_assignments_count: number
  properties_with_assignments: number
}

export interface AccessibleProperty {
  id: number
  name: string
}

export interface RoleUser {
  assignment_id: number
  person_id: number
  person_name: string | null
  property_id: number
  property_name: string | null
  starts_at: string | null
  ends_at: string | null
}
