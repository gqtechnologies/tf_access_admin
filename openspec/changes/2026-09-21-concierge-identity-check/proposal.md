## Why

En portería el conserje solo debe decidir una cosa: si la persona que se presenta es la de la invitación. Hoy la app le pide patente y nota, registra salidas y no le muestra nada con qué comparar. La verificación será visual: la foto de perfil que el visitante subió en la app contra la persona presente.

## What Changes

- El listado de conserjería expone `visitor.avatar_url` (foto de perfil del `User` del visitante).
- **Foto obligatoria**: en la API móvil de conserjería una visita sin foto del visitante no admite ingreso (`can_check_in: false`, `POST check_in` → 422 `api.concierge.photo_required`).
- `POST /api/v1/private/concierge/visits/:id/deny_entry`: la visita sigue `authorized`, se registra el evento `entry_denied` y se envía un push `visit_entry_denied` **solo a quien invitó** (`authorized_by`, o `created_by` si falta). Enfriamiento de 5 minutos por visita.
- `check_in` de la API móvil deja de aceptar patente y nota.

## Capabilities

### Modified Capabilities

- `mobile-private-api`: foto del visitante, foto obligatoria e ingreso denegado en conserjería.
- `fcm-push-notifications`: tipo `visit_entry_denied`.

## Impact

Sin migraciones. `Visits::CheckIn` y la conserjería web no cambian: la exigencia de foto aplica solo al canal móvil, que es donde existe la verificación visual. Nuevo `Visits::DenyEntry`, `Notifications::VisitEntryDeniedPushPayload`, `VisitEventTypes::ENTRY_DENIED`, `NotificationTypes::VISIT_ENTRY_DENIED`.

## Non-goals

- Exigir foto en la conserjería web. Registrar salidas desde la app. Avisar a otros residentes de la unidad. Reconocimiento facial.
