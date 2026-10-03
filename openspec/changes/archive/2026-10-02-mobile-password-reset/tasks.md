# Tasks

## 1. Backend

- [x] 1.1 Ruta `POST /api/v1/auth/password` y `Api::V1::Auth::PasswordsController#create` (D1, D2, D4); verificar con el test del controlador.
- [x] 1.2 `tenant_url_options_for` usa `ActsAsTenant.current_tenant` como respaldo (D3); verificar con el test del host del enlace.

## 2. Tests

- [x] 2.1 `test/controllers/api/v1/auth/passwords_controller_test.rb`: miembro, correo desconocido, otra organización, desactivado, sin confirmar, correo vacío, organización inexistente, host del enlace; verde con `PARALLEL_WORKERS=1 bin/rails test`.

## 3. Validación

- [x] 3.1 `bundle exec rubocop` sobre los archivos tocados y `bundle exec brakeman` sin advertencias nuevas.
- [ ] 3.2 Prueba manual tras desplegar: pedir el correo desde la app, abrir el enlace y cambiar la clave. (Usuario)
