## Why

Conserjería no tiene cómo saber de qué unidad es el auto que está en la entrada. La tabla `vehicles` existe sin reglas, endpoints ni pantallas.

## What Changes

- Los residentes (ocupantes o propietarios vigentes) registran y dan de baja los vehículos de su unidad: patente, tipo, marca, modelo y color. La patente se normaliza (mayúsculas, sin espacios ni guiones) y es única en la organización.
- Conserjería busca por parte de la patente en la propiedad que opera y ve unidad y residente.
- El admin ve el registro por propiedad en `/admin/vehicles`, con búsqueda por patente y baja.
- La patente se guarda en `metadata` con un índice ciego en `plate_number_digest`, igual que el documento de las personas, porque el proyecto no tiene configurado el cifrado de Active Record (`plate_number_ciphertext` queda sin uso).
- API: `GET/POST/DELETE /api/v1/private/units/:unit_id/vehicles`, `GET /api/v1/private/concierge/vehicles`.
- Sin migraciones.

## Capabilities

### New Capabilities
- `vehicles`: registro de vehículos por unidad y búsqueda por patente.

### Modified Capabilities

## Impact

- `Vehicle`, `Unit`; controladores de residente, conserjería y admin; serializer; rutas; página `admin/vehicles/index`; sidebar; locales.
- Apilado sobre `2026-10-02-authorized-residents`.
