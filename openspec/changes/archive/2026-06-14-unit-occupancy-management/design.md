## Context

Rails + Inertia + Vue multi-tenant para administración de propiedades residenciales.

**Estado actual:**
- Tabla y modelo `UnitOccupancy` **ya existen** (`unit_occupancies`) con `organization_id`, `unit_id`, `person_id`, `occupancy_type`, `can_authorize_visits`, `starts_at`, `ends_at`, `status`, `metadata`, y campos adicionales (`can_reserve_common_areas`, `can_withdraw_parcels`, `source` polimórfico).
- `OccupancyTypes` define hoy: `owner`, `tenant`, `family`, `other` — hay que ampliar al catálogo de negocio solicitado.
- **No** hay `deleted_at` / `acts_as_paranoid` en `UnitOccupancy` (a diferencia de `UnitOwnership`).
- **No** hay controller, policy, servicios, serializers ni UI admin para ocupantes.
- Vista `admin/units/show` tiene pestaña Propietarios implementada (`UnitOwnersPanel`); otras pestañas son placeholder.
- CRUD de propietarios (`UnitOwnerships::*`) sirve como **plantilla** probada: drawer multi-paso, `FindExistingPerson`, auditoría, Pundit, Inertia redirect con errores.
- Existe modelo paralelo `AuthorizedResident` — **no** se unifica en este change.

**Restricciones:** `acts_as_tenant`, Pundit, convenciones CRUD admin, auditoría, aislamiento por organización.

## Goals / Non-Goals

**Goals:**
- Listar ocupantes activos e históricos de una unidad con paginación server-side.
- Alta de ocupante vía persona existente o nueva (transacción atómica).
- Editar tipo de ocupación, `can_authorize_visits`, fechas y estado activo/inactivo.
- Soft delete de ocupante preservando historial y auditoría.
- Sección UI separada de Propietarios con drawer de 4 pasos y footer `flex justify-between`.
- Preparar reglas de dominio para futura integración con visitas.

**Non-Goals:**
- Consumir ocupantes en el flujo de visitas (approve/deny) — fase posterior.
- Gestionar `can_reserve_common_areas` / `can_withdraw_parcels` en UI.
- Consolidar o deprecar `AuthorizedResident`.
- Sincronizar automáticamente `UnitOwnership` → `UnitOccupancy`.
- Importación masiva de ocupantes.

## Decisions

### 1. Extender modelo existente (no crear tabla nueva)

Usar `unit_occupancies` tal como está, con migraciones incrementales:
- `deleted_at` + `acts_as_paranoid`
- Índice único parcial para ocupación activa por persona+unidad
- Ampliar `OccupancyTypes`

**Rationale:** El esquema ya modela el dominio; evita duplicación con `authorized_residents`.

**Alternativa descartada:** Nueva tabla — redundante y costosa.

### 2. Catálogo de `occupancy_type`

Valores objetivo:

| Valor | Descripción |
|-------|-------------|
| `owner_resident` | Propietario que también reside |
| `tenant` | Arrendatario |
| `family_member` | Familiar autorizado |
| `temporary_resident` | Residente temporal |
| `authorized_manager` | Administrador/gestor autorizado |
| `other` | Otro |

Migración de datos legacy: `owner` → `owner_resident`, `family` → `family_member`; `tenant` y `other` se mantienen.

**Rationale:** Alineación con requisitos de negocio y visitas.

### 3. Estado con `status` string (no boolean `active`)

Reutilizar columna `status` existente con valores al menos `active` / `inactive` (patrón similar a `UnitOwnership`).

Activar/inactivar = update de `status`. Soft delete = `destroy` vía `acts_as_paranoid`.

**Rationale:** Consistencia con el esquema actual; evita columna redundante.

### 4. Rutas anidadas bajo unidad

```
POST   /admin/residential_properties/:id/units/:unit_id/occupancies
PATCH  /admin/residential_properties/:id/units/:unit_id/occupancies/:id
DELETE /admin/residential_properties/:id/units/:unit_id/occupancies/:id
```

**Rationale:** Simétrico a `ownerships`; scope de autorización claro.

### 5. Service objects

| Servicio | Responsabilidad |
|----------|-----------------|
| `UnitOccupancies::Create` | Persona existente + datos de ocupación |
| `UnitOccupancies::CreateWithPerson` | Persona nueva + ocupación en transacción |
| `UnitOccupancies::Update` | Tipo, permisos, fechas, status |
| `UnitOccupancies::Destroy` | Soft delete |

Reutilizar `UnitOwnerships::FindExistingPerson` (o extraer a `Persons::FindExistingInOrganization`) para deduplicación.

**Rationale:** Misma arquitectura probada en propietarios.

### 6. Drawer multi-paso

| Paso | ID | Contenido |
|------|-----|-----------|
| 1 | `choose` | Buscar persona existente vs crear nueva |
| 2a | `search` | Búsqueda paginada de `Person` (org actual) |
| 2b | `create` | Formulario persona mínima (nombre, documento, email) |
| 3 | `assign` | Tipo ocupación, `can_authorize_visits`, `starts_at`, `ends_at` opcional |
| 4 | `confirm` | Resumen antes de crear |

Footer del drawer: `flex justify-between` — secundario izquierda, primario derecha (reutilizar `UnitAddOwnerDrawerFooter` o variante).

Composable: `useUnitAddOccupantDrawer` (estado, snapshot sessionStorage para errores Inertia).

**Rationale:** Paridad UX con propietarios + paso confirmación explícito del requisito.

### 7. Ubicación en UI

- Nueva pestaña `occupants` en `admin/units/show` (o sección dentro de tab existente si el diseño lo prefiere — **decisión: pestaña dedicada** "Residentes").
- Visualmente separada de `owners`; no mezclar tablas.

Props Inertia en `UnitsController#show`: `occupancies`, `occupancies_pagination` cuando tab activo o siempre (patrón owners).

### 8. Autorización

`UnitOccupancyPolicy`: `create?`, `update?`, `destroy?`, `index?`/`show?` implícitos vía scope — requiere `admin?` + `same_organization?` vía `unit` y `person`.

Scope: ocupaciones de unidades en tenant actual.

### 9. Auditoría e historial

- `audited` en `UnitOccupancy` (campos: `occupancy_type`, `can_authorize_visits`, `starts_at`, `ends_at`, `status`, `person_id`), `associated_with: :unit`.
- Extender `Unit::ChangeHistory` para describir eventos de `UnitOccupancy`.

### 10. Regla visitas (dominio, no UI)

Método de consulta (p. ej. `UnitOccupancy.active_authorizers_for(unit)`) que retorne personas con `status: active`, `can_authorize_visits: true`, y vigencia que incluya hoy (`starts_at <= now`, `ends_at` nil o `>= now`).

Integración en `Visit` — **non-goal** de este change; dejar servicio/query listo.

### 11. Manejo de fechas de vigencia

La UI tratará `starts_at` y `ends_at` como fechas (sin componente de hora).

Durante la persistencia:

- `starts_at` se normalizará al inicio del día (`00:00:00`)
- `ends_at` se normalizará al final del día (`23:59:59`)

utilizando la zona horaria configurada para la aplicación u organización.

Las validaciones de vigencia y los métodos de consulta de ocupantes activos deberán considerar esta normalización.

**Rationale:** Los usuarios gestionan ocupaciones por día, no por hora. Esto evita errores de vigencia y simplifica la experiencia de administración.

### 12. Validación unicidad activa

Modelo + índice DB:

```sql
UNIQUE (organization_id, unit_id, person_id) WHERE deleted_at IS NULL
```

Validación Ruby espejo con mensaje i18n.

### 23. Warning por ocupación activa en otra unidad

Al seleccionar una persona como ocupante, el sistema debe consultar si la persona posee ocupaciones activas en otras unidades de la misma organización.

Si existen coincidencias, el drawer debe mostrar un warning antes de confirmar:

> Esta persona ya figura como residente/ocupante activo en otra unidad.

El warning debe incluir, cuando esté disponible:

- unidad
- propiedad
- tipo de ocupación
- fecha de inicio

Este warning no bloquea la asignación. El administrador puede continuar y confirmar.

## Risks / Trade-offs

| Riesgo | Mitigación |
|--------|------------|
| Solapamiento `UnitOccupancy` vs `AuthorizedResident` | Documentar que admin UI usa solo `UnitOccupancy`; no tocar `authorized_residents` |
| Migración de `occupancy_type` rompe datos | Script de migración con mapa explícito; validar en staging |
| Duplicar mucho código del flujo de propietarios | Extraer componentes compartidos (footer drawer, person search step, create person fields) donde sea práctico |
| Confusión propietario vs ocupante | Copy UI claro; no auto-vincular ownership → occupancy |
| `starts_at` es datetime en DB vs date en UI | Normalizar a inicio de día en servicios; documentar en forms |

## Migration Plan

1. Migración DB: `deleted_at`, índice único parcial, migración de enums.
2. Modelo + validaciones + `acts_as_paranoid` + `audited`.
3. Backend: policy, rutas, servicios, controller, serializer, change history.
4. Frontend: tab, panel, tabla, drawers, composable.
5. Tests backend + smoke manual UI.
6. **Rollback:** revertir rutas/UI; datos en `unit_occupancies` permanecen.

## Open Questions
- ¿El paso `confirm` debe permitir editar inline o solo lectura?
