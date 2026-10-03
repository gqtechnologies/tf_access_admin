## Why

Un residente puede crear y listar visitas desde la app móvil, pero no puede ver el detalle de una visita, cancelarla ni volver a enviarle la invitación al visitante. Esas acciones solo existen en el admin web (`Admin::VisitsController`), y el reenvío del admin resuelve otro problema: reintenta el push fallido hacia los residentes y exige `manage_visits`.

Objetivo de producto: el residente gestiona desde la app las visitas de su unidad. Abre una visita, ve sus datos, la cancela si aún es cancelable y reenvía la invitación al visitante si no le llegó.

## What Changes

- **Detalle de visita**: `GET /api/v1/private/units/:unit_id/visits/:id` con `Api::Private::VisitDetailSerializer`. Incluye los flags `can_cancel` y `can_resend` calculados en el servidor.
- **Cancelar visita**: `DELETE /api/v1/private/units/:unit_id/visits/:id`. Reutiliza `Visits::Cancel` sin cambios (la policy ya acepta `authorize_visits`).
- **Reenviar invitación al visitante**: `POST /api/v1/private/units/:unit_id/visits/:id/resend_invitation`. Servicio nuevo `Visits::ResendVisitorInvitation` que delega en `Visits::NotifyVisitor`, con enfriamiento de 5 minutos y evento en el historial.
- **Tipo de evento** `invitation_resent` en `VisitEventTypes`.

## Capabilities

### Modified Capabilities

- `mobile-private-api`: tres endpoints nuevos anidados bajo la unidad (detalle, cancelar, reenviar invitación).
- `residential-visit-management`: reenvío de la invitación al visitante por parte del residente, con enfriamiento.

## Impact

**Bounded context:** Visits, API privada. Integración con la app móvil (change `2026-09-21-visit-detail-cancel-resend` en `tf_access_mobile`).

**Modelos y tablas:** sin migraciones. `visits.metadata` gana la clave `visitor_invitation_resent_at` (ISO 8601). `visit_status_histories` recibe eventos `invitation_resent`.

**Servicios:** nuevo `Visits::ResendVisitorInvitation`; `Visits::Cancel` y `Visits::NotifyVisitor` sin cambios; nuevo `Api::Private::VisitDetailSerializer`; `Api::V1::Private::Units::VisitsController` (+`show`, `destroy`, `resend_invitation`).

**Tenant isolation:** la visita se carga siempre con `@unit.visits.find(params[:id])`, con `@unit` resuelta bajo `ActsAsTenant`. Una visita de otra unidad u otra organización responde 404. `authorize_resident!` se aplica a las tres acciones.

**Dependencias:** `2026-09-14-mobile-visitor-invitations` (define `Visits::NotifyVisitor` y `mobile-private-api`).

## Non-goals

- Editar una visita desde la app.
- Autorizar visitas `pending` (requiere contrato propio).
- Conserjería móvil (check-in/check-out).
- Exponer el reintento de push a residentes del admin (`Visits::ResendNotification`).
- Exponer el documento del visitante en el detalle.
