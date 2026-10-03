## Why

Nanas, choferes y familiares que no viven en la unidad entran a diario y hoy necesitan una invitación cada vez, o el residente baja a buscarlos. La tabla `authorized_residents` existe sin flujo ni pantallas.

## What Changes

- Un ocupante que autoriza visitas o un propietario propone una persona autorizada para su unidad: nombre, correo, documento, relación, término opcional y si puede retirar encomiendas. La persona se resuelve o crea por correo como los visitantes.
- La solicitud queda pendiente hasta que la administración (quien gestiona los residentes de la propiedad, `manage_occupancies`) la aprueba o rechaza en `/admin/authorized_residents`; también puede revocarla. El residente que la propuso recibe push `authorized_person`.
- Aprobada y vigente, la persona: aparece en la lista de conserjería para entrar sin invitación (búsqueda por nombre, documento o unidad) y, si se indicó, puede retirar encomiendas de la unidad.
- El residente puede retirar su propuesta o la autorización.
- API: `GET/POST /api/v1/private/units/:unit_id/authorized_people`, `POST .../:id/withdraw`, `GET /api/v1/private/concierge/authorized_people`.
- Sin migraciones.

## Capabilities

### New Capabilities
- `authorized-residents`: personas autorizadas por una unidad.

### Modified Capabilities
- `parcel-deliveries`: las personas autorizadas con permiso de retiro pueden retirar encomiendas.

## Impact

- `AuthorizedResident` (+ `AuthorizedResidentStatuses`), `NotificationTypes`, `AuthorizedResidentPolicy`, `AuthorizedResidents::Propose`/`Decide`/`Withdraw`, `Notifications::AuthorizedPersonPushPayload`, `Parcels::EligibleWithdrawers`.
- Controladores de residente, conserjería y admin, serializer, rutas, página `admin/authorized_residents/index`, sidebar, locales.
- Apilado sobre `2026-10-02-incidents`.
