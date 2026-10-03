## Why

La administración no tiene cómo comunicar algo a los residentes (cortes de agua, mantenciones, asambleas) desde la plataforma. Las tablas `announcements`, `announcement_reads` y `announcement_targets` existen desde el modelo inicial sin pantallas ni endpoints.

## What Changes

- Avisos por propiedad con estados `draft` → `published` → `archived`, título, mensaje, categoría, prioridad, vencimiento opcional y "pedir confirmación de lectura".
- Capacidad nueva `manage_announcements` para administradores de propiedad y de organización.
- Al publicar, push `announcement` a todas las personas con ocupación o propiedad vigente en cualquier unidad de la propiedad, una vez por persona.
- Admin web `/admin/announcements`: lista por propiedad y estado con lecturas y confirmaciones, alta y edición de borradores, publicar (con confirmación que dice a cuántas personas llega) y archivar.
- API del residente: `GET /api/v1/private/announcements`, `GET /announcements/:id` (registra la lectura) y `POST /announcements/:id/acknowledge`.
- Sin migraciones. `announcement_targets` (segmentar por sección o unidad) queda sin uso por ahora.

## Capabilities

### New Capabilities
- `announcements`: avisos de la administración a los residentes de una propiedad.

### Modified Capabilities

## Impact

- `Announcement` (+ `AnnouncementStatuses`), `ResidentialProperty`, `Authorization::Capabilities`, `Authorization::ActiveRelationships`, `OperationalRoles::Presentation`, `AnnouncementPolicy`, `Announcements::Publish`/`Archive`, `Notifications::AnnouncementPushPayload`/`PushPayload`.
- `Admin::AnnouncementsController`, `Api::V1::Private::AnnouncementsController`, rutas, página `admin/announcements/index` y su drawer, sidebar, locales `es`/`en`/`pt`.
