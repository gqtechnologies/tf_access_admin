## Why

Una persona sin cuenta no puede registrarse: las cuentas solo nacen de una invitación del administrador o de un residente. Eso impide que alguien se cree un usuario por su cuenta para que después lo inviten, y el "Regístrate" del login de la app no lleva a ningún lado.

## What Changes

- Nuevo endpoint `POST /api/v1/auth/social` (`provider`: `apple` | `google`, `id_token`, y `name`/`dni` la primera vez).
- El token de identidad se verifica contra las claves públicas del proveedor: firma RS256, emisor, vencimiento y audiencia (que el token sea de esta app).
- Correo verificado que ya es miembro de la organización → entra a esa cuenta con su rol. Correo con cuenta en otra organización, o con una persona ya invitada aquí → se suma como visitante. Correo desconocido → cuenta nueva de visitante, confirmada.
- Para crear la cuenta se exigen nombre y documento; si faltan, `422` con `code: "profile_required"` y la lista de lo que falta.
- Configuración por entorno: `APPLE_SIGN_IN_AUDIENCES` (por defecto el bundle id de la app) y `GOOGLE_SIGN_IN_CLIENT_IDS` (sin valor por defecto: Google responde `503` hasta configurarlo).
- La respuesta de sesión del login se extrae a `Api::JwtSessionResponse` para compartirla.

## Capabilities

### New Capabilities

### Modified Capabilities
- `mobile-client-auth`: agrega ingreso y registro con Apple y Google.

## Impact

- Nuevos: `SocialAuth::TokenVerifier`, `SocialAuth::Jwks`, `Accounts::SocialSignIn`, `Api::V1::Auth::SocialSessionsController`, `Api::JwtSessionResponse`.
- Tocados: `Api::V1::Auth::SessionsController`, `config/initializers/warden_jwt_api_routes.rb`, rutas, locales.
- Sin migraciones y sin gemas nuevas (`jwt` ya viene con `devise-jwt`).
- Apilado sobre `2026-10-02-mobile-notifications`.
