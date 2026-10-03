## Why

Un push que el usuario no toca se pierde: la app no tiene dónde volver a ver que llegó una encomienda, que hay una visita por autorizar o que se le negó el ingreso a alguien. El backend ya guarda cada aviso en `notifications` con `read_at`, pero no lo expone.

## What Changes

- `GET /api/v1/private/notifications?page=`: avisos push dirigidos a la persona actual en los últimos 60 días, del más reciente al más antiguo, con el mismo título, cuerpo y `data` que el push, más `unread_count` y paginación. Incluye los avisos cuyo push no llegó (sin dispositivo o fallido).
- `POST /api/v1/private/notifications/:id/read` y `POST /api/v1/private/notifications/read_all`.
- `Notifications::PushPayload` concentra la elección del constructor de payload, usada por el job de envío y por la bandeja.

## Capabilities

### New Capabilities

### Modified Capabilities
- `mobile-private-api`: agrega la bandeja de notificaciones.

## Impact

- `config/routes.rb`, `app/controllers/api/v1/private/notifications_controller.rb`, `app/services/notifications/push_payload.rb`, `app/jobs/deliver_push_notification_job.rb`.
- Test: `test/controllers/api/v1/private/notifications_controller_test.rb`. Sin migraciones.
- Apilado sobre `2026-10-02-mobile-change-password`.
