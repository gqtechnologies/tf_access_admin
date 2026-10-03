## Context

Login (`Api::V1::Auth::SessionsController#create`) salta `set_current_organization` y resuelve la organización a mano, para responder `401` con su propio mensaje. `User.find_for_authentication(email:, organization_id:)` ya filtra por membresía. Devise envía las instrucciones con `deliver_now` y la plantilla `reset_password_instructions` llama a `tenant_url_options_for(@resource)`, que solo conoce `resource.organization`.

## Goals / Non-Goals

**Goals:** pedir el correo desde la app sin enumerar cuentas; que el enlace funcione.

**Non-Goals:** cambiar la contraseña dentro de la app (deep link con token), recuperar cuentas no confirmadas (para eso está la invitación de onboarding).

## Decisions

### D1 — Endpoint en `/api/v1/auth`, junto al login
La app ya calcula `authUrl()` para login/logout; el reseteo es la misma familia y tampoco lleva token.

### D2 — Respuesta `202` uniforme
Mismo cuerpo `{ data: { status: "requested" } }` en todos los casos con organización válida. La única distinción visible es `422` por correo vacío y `401` por organización inexistente, que no revelan nada de cuentas.

### D3 — Tenant en el mailer vía `ActsAsTenant.current_tenant`
El envío ocurre dentro de `ActsAsTenant.with_tenant(organization)`; como Devise entrega con `deliver_now`, la plantilla se renderiza con ese tenant activo. `tenant_url_options_for` cae a `ActsAsTenant.current_tenant` cuando el recurso no tiene `organization`. En la web, `POST /users/password` ya corre con el tenant del subdominio, así que también queda corregida. Alternativa descartada: pasar el subdominio en las opciones de Devise, que las convierte en cabeceras del correo.

### D4 — `rate_limit` de Rails
`rate_limit to: 5, within: 15.minutes, only: :create` sobre `request.remote_ip`, con el cache store de la app. En test (`null_store`) no aplica, por eso no hay test de `429`.

## Risks / Trade-offs

- [Si Devise pasara a `deliver_later`, el tenant se perdería en el job] → Un test verifica el host del enlace en el correo entregado.
- [El rate limit es por IP y comparte cache entre instancias solo si el cache store es compartido] → Aceptable; Devise además invalida tokens anteriores al generar uno nuevo.
