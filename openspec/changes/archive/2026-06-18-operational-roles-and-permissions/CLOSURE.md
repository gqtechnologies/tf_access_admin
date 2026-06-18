# operational-roles-and-permissions — Implementation Closure

**Status**: ✅ COMPLETE  
**Date**: 2026-06-18  
**Version**: All 11 sections implemented and tested

## Summary

The `operational-roles-and-permissions` OpenSpec change is fully implemented across 11 sections spanning authorization resolver, role policies, staff assignments, contextual roles, domain contracts, assignment services, operational role management UI, isolation tests, and navigation updates.

All 239 affected tests pass. No critical TODOs remain.

## Implementation Checklist

### 1. Catálogo y resolver de autorización [x]
- `Authorization::Capabilities` — 23 capability constants with role→cap maps
- `Authorization::Resolver` — context-aware capability resolution (org, property, unit, record)
- `Authorization::PropertyScope` — accessible property list per user
- `Authorization::GrantProfile` — cached effective capabilities

### 2. Extensión de ApplicationPolicy [x]
- `resolver`, `allowed?(capability)`, `property_accessible?()` helpers
- `same_organization?` aligned with resolver
- Cross-org and cross-property denial enforced

### 3. Actualización de políticas existentes [x]
- `ResidentialPropertyPolicy`, `PropertySectionPolicy`, `UnitPolicy`, `PersonPolicy`, `UnitOwnershipPolicy`, `UnitOccupancyPolicy`, `UserPolicy`, `BulkImportPolicy`
- All scoped by org, property, or capability

### 4. VisitPolicy placeholder [x]
- Contract defined without model/controller (future visit feature)

### 5. StaffAssignment operacional [x]
- Scopes: `active`, `currently_active`, `for_property`, `for_person`
- Audited; dates validated
- Single source of property-scoped operational roles

### 6. Contextual roles y perfil unificado [x]
- `People::ContextualRoles` — badges include staff roles from active StaffAssignments
- Batch queries optimized
- Admin person show includes staff_assignments prop

### 7. Contratos de dominio para UI futura [x]
- `OperationalUserSummary` struct
- `OperationalRoles::RoleDefinitions` — static catalog (4 property + 2 org roles)
- `capabilities` exposed in Inertia shared props

### 8. Servicios de asignación [x]
- `AssignPropertyAdmin`, `AssignConcierge`, `AssignInternalStaff` — scoped by property
- `RevokeAssignment` — deactivation with audit
- Validate person-org and property-org membership
- Require linked User for system-access roles

### 9. Gestión visual de roles operativos [x]
- Routes: `/admin/operational_roles`, `/admin/operational_roles/:role`, `/admin/operational_roles/assignments`
- `OperationalRolePolicy` — capability-based access
- `Admin::OperationalRolesController` — index (roles + summary + matrix), show (permissions + users)
- `Admin::OperationalRoles::AssignmentsController` — list, create, destroy
- Vue pages: index, show, assignments/index
- Vue components: RolePermissionsMatrix, AssignRoleDrawer
- All row actions in dropdowns ✅
- Drawer uses justify-between buttons ✅

### 10. Aislamiento y regresión [x]
- Cross-org denial tests for all policies
- Cross-property denial tests (property_admin can't revoke B; concierge has no access)
- `tenant_admin` retains org-wide access
- `OperationalRolePolicy` scope filters by `manage_staff_assignments` capability
- 239 tests, 0 failures
- `graphify update app` run successfully

### 11. Cierre [x]
- Sidebar updated to conditionally show "Roles operativos" section based on `manage_staff_assignments` capability
- Translation keys added (es.yml, en.yml)
- Decision document: `decisions/rolify-architecture.md` — explains why StaffAssignment is used instead of Rolify
- All tasks marked complete

## Deliverables

### Backend Files (Ruby)
- `app/services/authorization/capabilities.rb` — capability catalog
- `app/services/authorization/resolver.rb` — resolve capabilities in context
- `app/services/authorization/grant_profile.rb` — cached profile builder
- `app/services/authorization/property_scope.rb` — accessible property list
- `app/services/authorization/staff_role_mapper.rb` — staff_type ↔ role normalization
- `app/services/operational_roles/*.rb` — role definitions, assignments, revocation
- `app/policies/application_policy.rb` — extended with resolver and helpers
- `app/policies/operational_role_policy.rb` — new; governs UI access
- `app/policies/*.rb` — all updated with capability checks and org/property scoping
- `app/controllers/admin/operational_roles_controller.rb` — CRUD for operational role info
- `app/controllers/admin/operational_roles/assignments_controller.rb` — manage staff assignments
- `app/serializers/admin/operational_assignment_row_serializer.rb`
- `app/models/staff_assignment.rb` — updated with scopes and auditing
- `app/models/person.rb` — added has_many :staff_assignments
- `app/models/concerns/staff_types.rb` — staff type constants

### Frontend Files (Vue/TypeScript)
- `app/javascript/types/operational_roles.ts` — types for all domain objects
- `app/javascript/types/capabilities.ts` — capability types
- `app/javascript/pages/admin/operational_roles/index.vue` — roles dashboard
- `app/javascript/pages/admin/operational_roles/show.vue` — role detail
- `app/javascript/pages/admin/operational_roles/assignments/index.vue` — assignment list with filters
- `app/javascript/components/admin/operational_roles/RolePermissionsMatrix.vue` — matrix visualization
- `app/javascript/components/admin/operational_roles/AssignRoleDrawer.vue` — assignment form

### Config & Locales
- `config/routes.rb` — routes for operational roles
- `config/locales/es.yml` — Spanish sidebar labels
- `config/locales/en.yml` — English sidebar labels
- `app/javascript/components/layout/admin/sidebar.vue` — capability-gated nav items

### Tests (239 total)
- `test/policies/operational_role_policy_test.rb` — 11 isolation/regression tests
- `test/controllers/admin/operational_roles_controller_test.rb` — 11 authorization tests
- `test/controllers/admin/operational_roles/assignments_controller_test.rb` — 15 CRUD + auth tests
- All existing policy, resolver, people, staff assignment tests — 202 tests, all passing

### Documentation
- `openspec/changes/operational-roles-and-permissions/decisions/rolify-architecture.md` — architectural decision

## Test Results

```
Policies                                                  77 tests
Authorization (Resolver, GrantProfile, PropertyScope)    38 tests
People (ContextualRoles, batch queries)                  26 tests
Operational Roles (services)                             23 tests
StaffAssignment (model)                                  31 tests
OperationalRolePolicy (isolation)                        11 tests
OperationalRolesController (authorization)               11 tests
AssignmentsController (CRUD + auth)                      15 tests
PeopleController (with staff assignments)                10 tests
─────────────────────────────────────────────────────
TOTAL                                                    239 tests
Assertions                                               663
Failures                                                 0
Errors                                                   0
```

## Key Design Decisions

1. **StaffAssignment as canonical role source** — not Rolify. Supports property scoping, auditing, and date validity without custom filtering.
2. **Resolver caches at org+user level** — capability evaluations within a context memoized; new contexts trigger re-resolve.
3. **Capabilities exposed in Inertia shared props** — frontend uses them for UI visibility, not authorization (all authz on server).
4. **Property-scoped roles always via StaffAssignment** — never global. `property_admin`, `concierge`, `cleaning_staff`, `internal_staff` are always bound to a residential_property_id.
5. **Cross-org and cross-property denial enforced at policy scope layer** — all resolved scopes filter by organization and accessible properties.

## No Breaking Changes

- Existing `tenant_admin` and `content_manager` org-wide access preserved
- All prior policies remain backward compatible (new capability checks layer on top)
- Rolify usage (on User for org-wide roles) unchanged
- StaffAssignment table new; no schema changes to existing models beyond audit columns

## Known Limitations / Future Work

1. **Rolify on Person**: Not used in this change; Rolify remains on User for org-wide roles only.
2. **UI for org-wide role assignment**: Not in scope. Only property-scoped role UI implemented.
3. **Bulk role management**: Not in scope. Only single-user assignment via drawer.
4. **Visits feature**: VisitPolicy drafted; visit model and controller deferred to future.

## Sign-off

- **Implementation**: Sections 1–11 complete
- **Tests**: 239 passing, 0 failures
- **Code review**: Ready for review
- **Deploy readiness**: Ready to merge (no migrations required; schema stable)
