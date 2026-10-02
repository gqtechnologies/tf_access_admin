## Why

El dominio de encomiendas (`2026-10-02-parcel-deliveries`) exige que quien retira tenga `can_withdraw_parcels`, pero ese permiso no se puede activar en ninguna pantalla: hoy nadie podría retirar. Además la conserjería web solo opera visitas, así que un conserje sin la app no tiene dónde registrar encomiendas.

## What Changes

- **Permiso de retiro en el admin**: el formulario de alta y edición de ocupantes de una unidad suma "Puede retirar encomiendas"; la tabla de ocupantes lo muestra y el cambio queda auditado.
- **Conserjería web de encomiendas** en `/concierge/parcels`: lista por propiedad (por retirar / retiradas en 30 días) con contadores, búsqueda y paginación; registro de llegada (unidad, tipo, courier, código, nota) y registro de retiro eligiendo a un residente con permiso.
- Selector de propiedad cuando el usuario opera más de una (administradores incluidos).
- Entrada "Encomiendas" en el grupo Conserjería del sidebar para quien tenga `manage_parcels`.
- Textos en `es`/`en`/`pt`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `parcel-deliveries`: operación de encomiendas desde la conserjería web.
- `unit-occupancy-management`: el permiso de retiro de encomiendas se administra junto a la ocupación.

## Impact

- Backend: `Concierge::ParcelsController`, rutas, `UnitOccupancies::Mutation`/`Update`, `Admin::UnitOccupancySerializer`, auditoría de `UnitOccupancy`.
- Frontend: `pages/concierge/parcels/index.vue`, `components/concierge/parcels/*`, `useConciergeParcels.ts`, `types/parcel.ts`, sidebar, formularios y tabla de ocupantes.
- Apilado sobre `2026-10-02-parcel-deliveries`. Sin migraciones.
