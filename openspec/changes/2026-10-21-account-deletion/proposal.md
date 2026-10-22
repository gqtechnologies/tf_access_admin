## Why

El App Store exige que una app que permite crear cuentas también permita eliminarlas desde la app, y Google Play pide lo mismo. Access 24 crea cuentas con Apple, con Google y desde las invitaciones de visita, y hoy no hay forma de eliminarlas.

## What Changes

- `DELETE /api/v1/private/me`: el usuario elimina su propia cuenta. Responde `204`; un super admin recibe `403`.
- La cuenta se anonimiza, no se borra: visitas, encomiendas, reservas e incidentes conservan su historial sin datos personales.
  - `User`: nombre "Persona eliminada", email `deleted-<id>@deleted.invalid` (el original queda libre), sin documento, teléfono, fecha de nacimiento, foto ni push token, contraseña aleatoria y `deactivated_at`.
  - Cada `Person` del usuario, en todas las organizaciones: "Persona eliminada", sin documento, contacto ni fecha de nacimiento, `inactive`, desvinculada del usuario y con la membresía revocada. Sus propiedades y ocupaciones se mantienen hasta que la administración las termine.
  - `VisitorProfile`, `VisitParticipant` y la auditoría de `Person` pierden los nombres y documentos que copiaron.
- La API privada rechaza con `401` cualquier token de un usuario desactivado, así que la sesión deja de servir en el acto.
- Sin migraciones.

## Capabilities

### New Capabilities
- `account-deletion`: el usuario elimina su cuenta desde la app y sus datos personales se anonimizan. Incluye que la API privada rechace tokens de usuarios desactivados.

### Modified Capabilities

## Impact

- `Accounts::DeleteAccount`, `Api::V1::Private::ProfilesController#destroy`, `Api::V1::Private::BaseController`, rutas, locales `es`/`en`/`pt`.
- Pendiente fuera de este cambio: revocar el token de Sign in with Apple (requiere la clave privada de Sign in with Apple en el servidor).
