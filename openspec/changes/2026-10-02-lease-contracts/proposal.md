## Why

Los arriendos se reflejan hoy creando ocupaciones a mano, sin registro del contrato, su propietario ni sus fechas. La tabla `lease_contracts` existe sin flujo ni pantallas.

## What Changes

- En `/admin/lease_contracts` (quien gestiona residentes, `manage_occupancies`) se registra un contrato como borrador: unidad, arrendatario (resuelto o creado por correo), propietario opcional entre los dueños vigentes de la unidad, fechas y permisos (autoriza visitas, reserva áreas comunes, retira encomiendas; todos activos por defecto).
- Activar crea la ocupación `tenant` del arrendatario para esas fechas, con esos permisos, enlazada al contrato como origen.
- Terminar fija la fecha de término (hoy por defecto, nunca antes del inicio) y cierra la ocupación al final de ese día.
- Sin migraciones ni cambios en la app.

## Capabilities

### New Capabilities
- `lease-contracts`: contratos de arriendo que gobiernan la ocupación del arrendatario.

### Modified Capabilities

## Impact

- `LeaseContract` (+ `LeaseStatuses`), `LeaseContracts::Create`/`Activate`/`Terminate`, `Admin::LeaseContractsController`, rutas, página `admin/lease_contracts/index` y su drawer, sidebar, locales.
- Apilado sobre `2026-10-02-staff-shifts`.
