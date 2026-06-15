## Why

La plataforma gestiona visitas a unidades residenciales, pero hoy solo expone propietarios legales (`UnitOwnership`) en la vista de unidad. En la práctica, quien autoriza una visita suele ser un arrendatario, familiar, residente temporal o administrador — no necesariamente el dueño legal. Sin un CRUD de **ocupantes/residentes** (`UnitOccupancy`), el dominio de visitas carece de datos confiables sobre quién vive o está autorizado en cada unidad.

## What Changes

- CRUD admin de **ocupantes por unidad**: listado paginado, alta (persona existente o nueva), edición, activación/inactivación y baja lógica.
- Nueva sección **Residentes / Ocupantes** en la vista de detalle de unidad, separada de Propietarios.
- La UI debe evitar mezclar propietarios y ocupantes en una misma tabla o flujo.
- Drawer multi-paso **Agregar ocupante** (buscar/crear persona → definir tipo, permiso de visitas y fechas → confirmar).
- Servicios de mutación (`UnitOccupancies::Create`, `CreateWithPerson`, `Update`, `Destroy`) siguiendo el patrón de `UnitOwnerships`.
- Validaciones: unicidad persona+unidad activa, fechas coherentes, solo ocupantes activos con `can_authorize_visits` pueden autorizar visitas (regla de dominio; integración con flujo de visitas fuera de alcance inicial).
- Autorización Pundit, auditoría (`audited`) e historial de cambios de unidad.
- Extender tipos de ocupación y añadir soft delete al modelo existente.
- Traducciones `es` / `en` / `pt`.

## Capabilities

### New Capabilities

- `unit-occupancy-management`: Administración de residentes/ocupantes de una unidad desde la vista de gestión (listado, drawer multi-paso, CRUD de `UnitOccupancy`, validaciones, auditoría y reglas de autorización de visitas).

### Modified Capabilities

- _(ninguna — `unit-owner-management` no cambia requisitos; este change es un dominio adyacente)_

## Impact

**Bounded context:** Units + Persons + Unit Occupancies (+ Visit domain consumer futuro).

**Modelos afectados:**
- `UnitOccupancy` (existente — ampliar validaciones, tipos, soft delete, auditoría)
- `Unit`, `Person` (asociaciones ya existentes)
- `OccupancyTypes` (ampliar valores)

**Migraciones previstas:**
- Añadir `deleted_at` a `unit_occupancies` + `acts_as_paranoid`
- Migración de valores `occupancy_type` (`owner` → `owner_resident`, etc.) si hay datos
- Índice único parcial para evitar duplicados por `(unit_id, person_id, organization_id)` considerando únicamente registros no eliminados mediante soft delete

**Backend nuevo:**
- `UnitOccupancyPolicy`
- `Admin::ResidentialProperties::UnitOccupanciesController` (create, update, destroy)
- Servicios `UnitOccupancies::*`
- `Admin::UnitOccupancySerializer`
- Extensión de `Unit::ChangeHistory` para audits de `UnitOccupancy`

**Frontend (Inertia + Vue):**
- Pestaña o panel `UnitOccupantsPanel` en `admin/units/show`
- `UnitOccupantsTable`, `UnitAddOccupantDrawer` y pasos (reutilizar patrones de propietarios)
- Composable `useUnitAddOccupantDrawer`
- Drawer de edición de ocupación

**Fuera de alcance explícito:**
- UI para `can_reserve_common_areas` / `can_withdraw_parcels` (campos ya en DB; posible fase posterior)
- Modelo `AuthorizedResident` (tabla paralela legacy; no consolidar en este change)
- Flujo completo de aprobación de visitas consumiendo ocupantes (solo dejar reglas listas)
- Auto-crear ocupante al dar de alta propietario legal

## Business Rules

- Una unidad puede tener múltiples ocupantes activos.
- Una persona puede ocupar múltiples unidades.
- Una misma persona puede tener distintos tipos de ocupación en diferentes unidades.
- No puede existir más de una ocupación **activa** para la misma persona y unidad.
- Los ocupantes con `status = active` y `can_authorize_visits = true` son considerados autorizadores válidos de visitas dentro del contexto de la unidad.
- Los propietarios legales (`UnitOwnership`) no son ocupantes salvo que se cree explícitamente un `UnitOccupancy` (p. ej. tipo `owner_resident`).
- UnitOccupancy no reemplaza ni migra automáticamente registros de AuthorizedResident durante este change.
- Quitar ocupante = soft delete; no eliminación física.
- Búsqueda/creación de personas con aislamiento por organización y deduplicación por documento/email.
- `ends_at >= starts_at` cuando `ends_at` esté presente.
- Una ocupación se considera activa cuando:
  - status = active
  - no ha sido eliminada mediante soft delete
  - starts_at <= fecha actual
  - ends_at es nulo o mayor o igual a la fecha actual
- Al asignar una persona como ocupante, si ya tiene una ocupación activa en otra unidad, el sistema debe mostrar un warning antes de confirmar la asignación. El warning no bloquea la creación.
