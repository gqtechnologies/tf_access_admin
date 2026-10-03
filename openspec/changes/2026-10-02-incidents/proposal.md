## Why

Los problemas del edificio (ruidos, filtraciones, portones trabados) se avisan por WhatsApp o en persona y no queda registro de quién los atendió ni cómo terminaron. La tabla `incidents`, con su historial, existe sin reglas, endpoints ni pantallas.

## What Changes

- Incidentes con estados `open` → `in_progress` → `resolved` / `dismissed`, categoría, descripción, prioridad y, opcionalmente, unidad o área común de la propiedad.
- Reportan los residentes (en una propiedad donde tienen ocupación o propiedad vigente, nombrando solo unidades propias) y el personal de portería con la capacidad nueva `report_incidents` (incluida en conserje y administrador de propiedad).
- Gestiona quien tenga la capacidad nueva `manage_incidents` (administradores de propiedad y de organización) en `/admin/incidents`: abiertos, en curso, cerrados; responsable, prioridad, estado y resolución (obligatoria para cerrar). Cada cambio de estado notifica por push `incident` a quien reportó.
- API: `GET /api/v1/private/incidents` (los reportados por uno) y `POST /api/v1/private/incidents`.
- Sin migraciones.

## Capabilities

### New Capabilities
- `incidents`: reporte y gestión de incidentes de una propiedad.

### Modified Capabilities

## Impact

- `Incident` (+ `IncidentStatuses`), capacidades y presentación, `IncidentPolicy`, `Incidents::Report`/`Update`, `Notifications::IncidentPushPayload`.
- `Admin::IncidentsController`, `Api::V1::Private::IncidentsController`, `Api::Private::IncidentSerializer`, página `admin/incidents/index` y su drawer, sidebar, locales.
- Apilado sobre `2026-10-02-common-area-reservations`.
