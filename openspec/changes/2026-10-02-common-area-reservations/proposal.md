## Why

Los edificios tienen quinchos, salas y piscinas que hoy se reservan fuera de la plataforma. Las tablas `common_areas`, `common_area_rules` y `common_area_reservations` (con su historial y una restricción que impide solapamientos) existen sin reglas de negocio, endpoints ni pantallas, y el permiso `can_reserve_common_areas` de los ocupantes no se puede activar.

## What Changes

- **Áreas comunes** por propiedad (admin web `/admin/common_areas`): nombre, tipo, capacidad, si requiere aprobación, disponible/cerrada, y reglas opcionales: horario de apertura y cierre, duración máxima, anticipación mínima, tope de reservas por unidad al mes e indicaciones.
- **Reservas**: estados `pending`, `approved`, `rejected`, `cancelled`. Reserva desde la app un ocupante vigente con `can_reserve_common_areas`; si el área exige aprobación queda pendiente, si no, aprobada al instante. Las reglas se validan en la zona horaria de la propiedad y la base de datos impide dos reservas activas que se solapen.
- **Decisiones** en el admin web `/admin/reservations` (por aprobar, próximas, historial): aprobar, rechazar con motivo o cancelar; el residente recibe push `reservation` con el resultado. El residente puede cancelar las suyas antes de que empiecen.
- Capacidad nueva `manage_common_areas` (administradores de propiedad y de organización).
- Casilla "Puede reservar áreas comunes" en el formulario y la tabla de ocupantes.
- API del residente: `GET /common_areas?unit_id=`, `GET /common_areas/:id/availability?day=`, `GET /reservations?unit_id=`, `POST /reservations`, `POST /reservations/:id/cancel`.
- Sin migraciones. El depósito (`requires_deposit`, `deposit_amount_cents`) queda fuera.

## Capabilities

### New Capabilities
- `common-area-reservations`: áreas comunes, sus reglas y su ciclo de reservas.

### Modified Capabilities
- `unit-occupancy-management`: el permiso de reservar áreas comunes se administra junto a la ocupación.

## Impact

- Modelos `CommonArea`, `CommonAreaReservation`, `Unit`, `UnitOccupancy`; `ReservationStatuses`; capacidades y presentación; `CommonAreaPolicy`.
- Servicios `Reservations::RuleCheck`, `Request`, `Decide`, `Cancel`, `Notify`; `Notifications::ReservationPushPayload`.
- Controladores `Admin::CommonAreasController`, `Admin::ReservationsController`, `Api::V1::Private::CommonAreasController`, `Api::V1::Private::ReservationsController`; concern `ManagedPropertyContext`; serializer `Api::Private::ReservationSerializer`.
- Páginas `admin/common_areas/index`, `admin/reservations/index`, formularios de ocupantes, sidebar, locales.
- Apilado sobre `2026-10-02-announcements`.
