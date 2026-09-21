## Context

`Concierge::VisitsController` (Inertia) resuelve la propiedad activa con `Authorization::Resolver#profile.property_capabilities`, lista con `policy_scope(Visit)` + pestañas + `Visits::ConciergeSearch`, y muta con `Visits::CheckIn` / `Visits::CheckOut`, que autorizan por `VisitPolicy` (`register_visit_entry` / `register_visit_exit`). Responde con redirecciones y props de página, por lo que no es reutilizable como API.

## Decisiones

### D1 — Rol `concierge`

`Api::RoleResolver`: tras `super_admin` y los roles organizacionales, devuelve `"concierge"` si existe un `StaffAssignment` activo (`status: active`, vigente hoy) con `staff_type: concierge` para la persona del usuario en la organización. Si no, `"resident"`. Un `tenant_admin` que además sea conserje sigue siendo `tenant_admin`.

### D2 — Propiedades del conserje

`GET concierge/properties` → `{ data: [{ id, name }] }`, las propiedades con `view_authorized_visits` en `property_capabilities`, ordenadas por nombre. Lista vacía → `200` con `[]`. Un concern `Api::V1::Private::Concierge::PropertyContext` expone `concierge_property_ids` y `load_property!` (403 `api.concierge.property_forbidden` si `property_id` falta o no pertenece al conjunto).

### D3 — Listado

`GET concierge/visits?property_id=&tab=&q=&page=`:

- Base: `policy_scope(Visit).where(residential_property_id: property.id)`.
- `tab`: `authorized` (por defecto) | `checked_in` | `checked_out`; valor desconocido → `authorized`. `checked_out` usa el scope `recently_checked_out`.
- `q` presente → `Visits::ConciergeSearch` sobre el scope de la pestaña, con la misma firma que usa el controlador web.
- Orden: `authorized` por `scheduled_at` asc; `checked_in` por `checked_in_at` desc; `checked_out` por `checked_out_at` desc.
- Paginación Kaminari, 25 por página. Respuesta: `{ data: [...], counters: { authorized, checked_in, checked_out }, pagination: { page, total_pages, total_count } }`. Los contadores se calculan sobre el scope de propiedad, sin `q`.

### D4 — Serializer

`Api::Private::ConciergeVisitSerializer`: `id`, `status`, `effective_status`, `scheduled_at`, `checked_in_at`, `checked_out_at`, `visitor { name }`, `unit { display_name }`, `authorized_by_name`, `can_check_in`, `can_check_out`.

- `can_check_in`: `VisitPolicy#check_in?` **y** estado `authorized` no vencido.
- `can_check_out`: `VisitPolicy#check_out?` **y** estado `checked_in`.

La policy recibe el `current_user` por `scope` del serializer, igual que `Concierge::VisitSerializer`.

### D5 — Ingreso y salida

`POST concierge/visits/:id/check_in` con `{ check_in: { vehicle_plate?, notes? } }` y `POST .../check_out` con `{ check_out: { notes? } }`. La visita se carga con `policy_scope(Visit).find` (404 fuera de alcance). Se llama al servicio con la misma firma que el controlador web, dejando `access_point`/`access_type`/`incident_type` en `nil`. Respuestas: `200 { data: <serializer> }`; `AASM::InvalidTransition` → 422 `api.concierge.invalid_transition`; `Visits::OperationalMetadataParams::InvalidMetadataError` → 422 con su mensaje; `Pundit::NotAuthorizedError` → 403 `api.concierge.not_authorized`. Si el servicio rechaza una autorización vencida con un error propio, se mapea a 422.

### D6 — i18n

`api.concierge.{property_forbidden,invalid_transition,not_authorized}` en `es`/`en`/`pt`.

## Riesgos

- **Coste de `policy.check_in?` por fila**: el serializer web ya lo hace; con 25 por página es aceptable. Memoizar el `Authorization::Resolver` por request si los tests muestran N+1 evidente.
- **Conserje con rol organizacional `visitor`** (fue invitado como visita antes): `visitor` gana en `TENANT_ROLE_PRIORITY`. Se resuelve poniendo la comprobación de conserje antes de `visitor` en el resolver.

## Testing

Solo archivos nuevos/tocados, `PARALLEL_WORKERS=1`:

- `test/services/api/role_resolver_test.rb`: conserje, conserje+visitor → concierge, tenant_admin+conserje → tenant_admin, asignación inactiva → resident.
- `test/controllers/api/v1/private/concierge/properties_controller_test.rb`: feliz, vacío para residente, 401.
- `test/controllers/api/v1/private/concierge/visits_controller_test.rb`: listado por pestaña con contadores, `q`, 403 sin asignación, 403 `property_id` ajeno, no filtra visitas de otra propiedad, payload sin correo/teléfono/documento; check-in feliz con patente, 422 desde `cancelled`, 404 de otra propiedad, 403 residente; check-out feliz, 422 desde `authorized`.
