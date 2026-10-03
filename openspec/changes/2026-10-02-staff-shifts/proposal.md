## Why

No queda registro de quién estuvo de turno en conserjería ni de lo que se entregó al relevo. La tabla `staff_shifts` existe sin flujo ni pantallas, y `parcel_deliveries.staff_shift_id` nunca se llena.

## What Changes

- El conserje inicia su turno en la propiedad donde tiene asignación vigente (uno abierto a la vez por persona) y lo cierra con una nota de entrega. Al consultar ve, además, la nota del último turno cerrado de la propiedad.
- Sin planificación: el rango planificado se registra igual al real.
- Las encomiendas recibidas por un conserje con turno abierto en esa propiedad quedan asociadas al turno.
- Bitácora en `/admin/staff_shifts` por propiedad y día (quien gestiona asignaciones de personal): conserje, inicio, término, duración, encomiendas recibidas y nota.
- API: `GET/POST /api/v1/private/concierge/shift`, `POST /api/v1/private/concierge/shift/close`.
- Sin migraciones.

## Capabilities

### New Capabilities
- `staff-shifts`: turnos de conserjería.

### Modified Capabilities

## Impact

- `StaffShift`, `Parcels::Receive`, `StaffShifts::Open`/`Close`, `StaffShiftPolicy`, controladores de conserjería y admin, rutas, página `admin/staff_shifts/index`, sidebar, locales.
- Apilado sobre `2026-10-02-vehicles`.
