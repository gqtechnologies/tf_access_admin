## Why

La conserjería solo existe en el admin web (`/concierge/visits`, Inertia). Un conserje que inicia sesión en la app móvil recibe `role: "resident"` — conserje no es un rol organizacional sino un `StaffAssignment` activo por propiedad — y ve un menú de residente sin unidades. En portería el dispositivo natural es el teléfono.

## What Changes

- **Rol `concierge` en la API**: `Api::RoleResolver` devuelve `concierge` cuando el usuario tiene un `StaffAssignment` activo de tipo `concierge` y ningún rol organizacional superior. Se refleja en login y `/me`.
- **Namespace `/api/v1/private/concierge`**:
  - `GET properties` — propiedades donde el usuario opera como conserje.
  - `GET visits?property_id=&tab=&q=&page=` — visitas operativas de una propiedad con contadores por pestaña y búsqueda (`Visits::ConciergeSearch`).
  - `POST visits/:id/check_in` y `POST visits/:id/check_out` — envuelven `Visits::CheckIn` / `Visits::CheckOut`.
- **`Api::Private::ConciergeVisitSerializer`**: payload mínimo, sin correo, teléfono ni documento del visitante.

## Capabilities

### Modified Capabilities

- `mobile-private-api`: endpoints de conserjería.
- `operational-roles-and-permissions`: rol de API `concierge` derivado de la asignación de staff.

## Impact

**Bounded context:** Visits (operación de portería), Authorization, API privada. Integración con `2026-09-21-concierge-mode` en `tf_access_mobile`.

**Modelos y tablas:** sin migraciones.

**Servicios:** `Api::RoleResolver`; nuevos `Api::V1::Private::Concierge::PropertiesController` y `VisitsController`; nuevo serializer. `Visits::CheckIn`, `Visits::CheckOut`, `Visits::ConciergeSearch` y `VisitPolicy` sin cambios.

**Tenant isolation:** toda consulta parte de `policy_scope(Visit)` (organización + `concierge_visible`) y se acota a una única propiedad sobre la que el usuario tiene `view_authorized_visits`. `property_id` ajeno → 403; visita de otra propiedad u organización → 404.

**Dependencias:** `concierge-visit-access-flow` (spec vigente), `2026-09-14-mobile-visitor-invitations`.

## Non-goals

- QR o código de acceso.
- Registrar visitas espontáneas desde portería.
- `access_point`, `access_type` e incidentes de salida desde la app.
- Push al residente al ingresar su visita.
- Usuario que sea conserje y residente a la vez: la API lo trata como conserje.
