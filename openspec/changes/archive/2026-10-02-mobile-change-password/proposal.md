## Why

Un usuario con sesión iniciada no puede cambiar su contraseña desde la app: la única vía es el correo de recuperación, pensado para quien la olvidó.

## What Changes

- Nuevo endpoint `PATCH /api/v1/private/me/password` con `current_password` y `password`.
- Rechazos `422` con `field` (`current_password` o `password`) y un mensaje: contraseña actual incorrecta, nueva igual a la actual, o nueva que no cumple la política (8+ caracteres, minúscula, mayúscula, número y símbolo).
- Límite de 5 intentos por usuario cada 15 minutos (`429`).
- La sesión actual sigue válida tras el cambio.

## Capabilities

### New Capabilities

### Modified Capabilities
- `mobile-private-api`: agrega el cambio de contraseña del usuario autenticado.

## Impact

- `config/routes.rb`, `app/controllers/api/v1/private/passwords_controller.rb`, locales `es`/`en`/`pt`.
- Test: `test/controllers/api/v1/private/passwords_controller_test.rb`. Sin migraciones.
