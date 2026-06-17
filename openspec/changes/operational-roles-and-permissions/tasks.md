## 1. Catálogo y resolver de autorización

- [x] 1.1 Crear `Authorization::Capabilities` con constantes y mapas por rol operativo MVP
- [x] 1.2 Crear `Authorization::Resolver` con contexto `user`, `organization`, `property: nil`, `unit: nil`, `record: nil`
- [x] 1.3 Implementar resolución en capas: rol organizacional → StaffAssignment activo por propiedad → ownership/occupancy activo por unidad
- [x] 1.4 Crear `Authorization::PropertyScope` para `accessible_property_ids`
- [x] 1.5 Memoizar en `Current` un resolver base por `user` + `organization`, y cachear evaluaciones por contexto (`property`, `unit`, `record`) sin reutilizar scopes incorrectos
- [x] 1.6 Tests unitarios del resolver por cada rol MVP (grant y deny)
- [x] 1.7 Garantizar que `property_admin`, `concierge`, `cleaning_staff` e `internal_staff` se resuelven exclusivamente por `StaffAssignment` activo asociado a una propiedad, nunca como roles globales

## 2. Extensión de ApplicationPolicy

- [ ] 2.1 Añadir `resolver`, `allowed?(capability)`, `property_accessible?(property)` a `ApplicationPolicy`
- [ ] 2.2 Implementar `record_residential_property` helper (o concern) para resolver propiedad del recurso
- [ ] 2.3 Mantener `same_organization?` y alinear con resolver
- [ ] 2.4 Tests de helpers de policy base

## 3. Actualización de políticas existentes

- [ ] 3.1 Actualizar `ResidentialPropertyPolicy` — capacidades y scope por propiedades accesibles
- [ ] 3.2 Actualizar `PropertySectionPolicy` — heredar alcance de propiedad padre
- [ ] 3.3 Actualizar `UnitPolicy` — `view_units` / `manage_units` scoped
- [ ] 3.4 Actualizar `PersonPolicy` — `view_people` / `manage_people`; residente ve su propia persona
- [ ] 3.5 Actualizar `UnitOwnershipPolicy` — `manage_ownerships` scoped
- [ ] 3.6 Actualizar `UnitOccupancyPolicy` — `manage_occupancies` scoped
- [ ] 3.7 Actualizar `UserPolicy` — `manage_users` solo Super Admin Org
- [ ] 3.8 Actualizar `BulkImportPolicy` — capacidades según alcance de propiedad
- [ ] 3.9 Tests de policy por rol y alcance: tenant_admin, property_admin de propiedad asignada, property_admin de otra propiedad, concierge de propiedad asignada, concierge de otra propiedad, resident/owner de unidad propia, client sin acceso

## 4. VisitPolicy placeholder

- [ ] 4.1 Crear contrato documentado para futura `VisitPolicy` sin crear modelo, migración, controller ni rutas de visitas
- [ ] 4.2 Definir métodos esperados: `index?`, `show?`, `create?`, `authorize?`, `check_in?`, `check_out?`
- [ ] 4.3 Definir reglas esperadas por capability: `create_visits`, `authorize_visits`, `register_visit_entry`, `register_visit_exit`

## 5. StaffAssignment operacional

- [ ] 5.1 Añadir scopes activos en `StaffAssignment` (`active`, vigencia por fechas)
- [ ] 5.2 Verificar que `StaffAssignment` activo sea la única fuente de roles operativos por propiedad dentro de `Authorization::Resolver`
- [ ] 5.3 Mapear `StaffTypes::MANAGER` ↔ `property_admin` en resolver y badges
- [ ] 5.4 Definir mapa de capacidades para staff types existentes, normalizando:
  - `manager` / `property_admin` → `property_admin`
  - `concierge` / `security` → `concierge`
  - `cleaning` / `cleaning_staff` → `cleaning_staff`
  - `maintenance` / `other` → `internal_staff`
- [ ] 5.5 Auditar `StaffAssignment` (create/update status)
- [ ] 5.6 Tests de integración staff → capacidades
- [ ] 5.7 Añadir validaciones de vigencia en `StaffAssignment`: `ends_at >= starts_at` y estado activo/inactivo consistente

## 6. Contextual roles y perfil unificado

- [ ] 6.1 Extender `People::ContextualRoles` con badges staff desde `StaffAssignment` activo
- [ ] 6.2 Actualizar `People::ContextualRoles.batch_for` para staff en batch
- [ ] 6.3 Exponer `staff_assignments` reales en `Admin::PeopleController#show`
- [ ] 6.4 Actualizar `PersonStaffTab` para listar asignaciones activas
- [ ] 6.5 Alinear `permissions` prop del perfil con `Authorization::Resolver`
- [ ] 6.6 Tests de contextual roles staff y permisos de perfil

## 7. Contratos de dominio para UI futura

- [ ] 7.1 Documentar `OperationalUserSummary` (serializer o type stub)
- [ ] 7.2 Definir contrato de entrada/salida para servicios `OperationalRoles::*` que serán implementados en sección 8
- [ ] 7.3 Exponer `capabilities` en shared props Inertia del layout admin
- [ ] 7.4 Tipos TypeScript `OperationalCapabilities` para frontend

## 8. Servicios de asignación (sin UI)

- [ ] 8.1 Implementar `OperationalRoles::AssignPropertyAdmin`
- [ ] 8.2 Implementar `OperationalRoles::AssignConcierge`
- [ ] 8.3 Implementar `OperationalRoles::AssignInternalStaff`
- [ ] 8.4 Implementar `OperationalRoles::RevokeAssignment`
- [ ] 8.5 Validar `person.user_id` presente cuando la asignación requiere acceso al sistema
- [ ] 8.6 Tests de servicios de asignación

## 9. Aislamiento y regresión

- [ ] 9.1 Tests cross-organization denial en todas las políticas actualizadas
- [ ] 9.2 Tests cross-property denial para property_admin y concierge
- [ ] 9.3 Verificar que `tenant_admin` existentes conservan acceso org-wide
- [ ] 9.4 Ejecutar suite de tests afectados (policies, resolver, people, units)
- [ ] 9.5 Ejecutar `graphify update app` tras cambios en código
- [ ] 9.6 Test explícito: usuario `property_admin` de Propiedad A no puede acceder ni modificar Propiedad B
- [ ] 9.7 Test explícito: usuario `concierge` de Propiedad A no puede consultar datos de Propiedad B

## 10. Cierre

- [ ] 10.1 Revisar navegación admin: ocultar ítems según `capabilities` en layout
- [ ] 10.2 Documentar decisión Rolify-on-Person vs User (follow-up opcional)
- [ ] 10.3 Archivar/sync specs delta al completar implementación
