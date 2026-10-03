## Why

Las visitas `pending` nacen en el admin web (`Visits::Create` cuando el actor no puede autorizar directamente) y disparan un push `visit_request` a los residentes autorizadores de la unidad. El residente no puede responder desde la app: `Visits::Authorize` no tiene endpoint móvil y rechazar no existe en el dominio (el estado `rejected` está definido sin transición ni servicio). Además, el payload del push no lleva `unit_id` ni `residential_property_id`, que la app necesita para abrir la gestión de visitas de la unidad, así que el toque siempre termina en Home.

## What Changes

- **Rechazo**: evento AASM `reject` (`pending → rejected`), servicio `Visits::Reject`, `VisitPolicy#reject?`, tipo de evento `rejected`.
- **Endpoints**: `POST /api/v1/private/units/:unit_id/visits/:id/authorize` y `.../reject`.
- **Aviso al visitante al autorizar** desde la app (`Visits::NotifyVisitor`), cuando tiene correo o cuenta. Rechazar no avisa.
- **Flags** `can_authorize` / `can_reject` en `Api::Private::VisitDetailSerializer`.
- **Push `visit_request`**: `data` suma `unit_id` y `residential_property_id`.

## Capabilities

### Modified Capabilities

- `mobile-private-api`: endpoints de autorización y rechazo; flags en el detalle.
- `residential-visit-management`: rechazo de visitas pendientes; aviso al visitante al autorizar.
- `fcm-push-notifications`: ids de unidad y propiedad en el payload de `visit_request`.

## Impact

**Bounded context:** Visits, Notifications, API privada. Integración con `2026-09-21-visit-authorize-reject` en `tf_access_mobile`.

**Modelos y tablas:** sin migraciones (`rejected` ya es un valor válido de `visits.status`).

**Servicios:** nuevo `Visits::Reject`; `Visit::StateMachine`, `VisitPolicy`, `VisitEventTypes`, `Notifications::VisitRequestPushPayload`, `Api::Private::VisitDetailSerializer`, `Api::V1::Private::Units::VisitsController`. `Visits::Authorize` sin cambios.

**Tenant isolation:** igual que el resto del controlador — visita resuelta vía `@unit.visits` bajo `ActsAsTenant`, con `authorize_resident!`.

**Dependencias:** `2026-09-21-mobile-visit-management`.

## Non-goals

- Crear visitas `pending` desde la app.
- Avisar a conserjería o al admin del resultado.
- Expiración automática de pendientes.
- Rechazar desde el admin web (la transición queda disponible, sin UI).
