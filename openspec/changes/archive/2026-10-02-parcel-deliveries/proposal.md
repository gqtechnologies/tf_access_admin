## Why

Las encomiendas que llegan a portería no se registran en ningún lado: la tabla `parcel_deliveries` existe desde el modelo inicial pero no tiene reglas, endpoints ni pantallas, y en la app la opción "Encargos" de la unidad está inerte. El residente no se entera de que llegó algo y no queda constancia de quién lo retiró.

## What Changes

- Dominio de encomiendas: estados `received` → `withdrawn`, historial de estado, servicios `Parcels::Receive` y `Parcels::Withdraw`.
- Nueva capacidad `manage_parcels` (registrar llegadas y retiros) para conserjes y administradores de propiedad; los administradores de la organización la tienen por ser org-wide.
- Al registrar una llegada se avisa por push (`parcel`) a **todas** las personas con ocupación o propiedad vigente en la unidad.
- El retiro solo puede registrarse a nombre de una persona con ocupación vigente y `can_withdraw_parcels` en esa unidad.
- API del residente: `GET /api/v1/private/units/:unit_id/parcels`.
- API de conserjería: `GET/POST /api/v1/private/concierge/parcels`, `GET /concierge/parcels/:id`, `POST /concierge/parcels/:id/withdraw`, `GET /concierge/units`.
- Sin migraciones: se usan las tablas existentes.

Fuera de este change (changes siguientes): pantallas de la app, conserjería web y el interruptor `can_withdraw_parcels` en el formulario de ocupantes del admin.

## Capabilities

### New Capabilities
- `parcel-deliveries`: registro de llegada y retiro de encomiendas, permisos, aviso a la unidad.

### Modified Capabilities
- `mobile-private-api`: endpoints de encomiendas para residentes y conserjes.

## Impact

- Modelos `ParcelDelivery`, `ParcelDeliveryStatusHistory`; `ParcelStatuses`; `Authorization::Capabilities`; `OperationalRoles::Presentation`; `ParcelDeliveryPolicy`.
- Servicios `Parcels::*`, `Notifications::ParcelPushPayload`, `DeliverPushNotificationJob`.
- Controladores `Api::V1::Private::Units::ParcelsController`, `Api::V1::Private::Concierge::ParcelsController`, `Api::V1::Private::Concierge::UnitsController`; `Api::ConciergePropertyContext`.
- Locales `es`/`en`/`pt`.
