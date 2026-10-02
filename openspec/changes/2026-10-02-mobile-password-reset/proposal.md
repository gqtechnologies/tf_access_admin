## Why

La app móvil muestra "¿Olvidaste tu contraseña?" pero no hace nada: quien olvida su clave depende de que un administrador lo resuelva. Además, el correo de recuperación que envía Devise arma el enlace sin el subdominio de la organización (`User` no tiene una `organization` única), así que el enlace cae en el dominio base y redirige al inicio en vez de mostrar el formulario de nueva contraseña.

## What Changes

- Nuevo endpoint `POST /api/v1/auth/password` (`email`), resuelto por subdominio o `X-Tenant-Subdomain` igual que el login. Envía las instrucciones de Devise solo a miembros confirmados y activos de esa organización y responde siempre `202` sin revelar si el correo existe.
- Límite de 5 solicitudes por IP cada 15 minutos (`429` con `Retry-After`).
- `ApplicationMailer#tenant_url_options_for` usa la organización actual (`ActsAsTenant.current_tenant`) cuando el recurso no tiene `organization`, de modo que el enlace del correo apunta a `<subdominio>.<host>/users/password/edit`. Corrige también la recuperación desde la web.
- El cambio de contraseña sigue ocurriendo en la página web existente; la app no recibe el token.

## Capabilities

### New Capabilities

### Modified Capabilities
- `mobile-client-auth`: agrega la solicitud de recuperación de contraseña desde la API.

## Impact

- `config/routes.rb`, `app/controllers/api/v1/auth/passwords_controller.rb` (nuevo), `app/mailers/application_mailer.rb`.
- Tests: `test/controllers/api/v1/auth/passwords_controller_test.rb`.
- Sin migraciones. Requiere que el envío de correo esté configurado en producción (ver pendientes de Resend/Mailgun).
