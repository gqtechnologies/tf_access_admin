## Context

Los servicios de onboarding existen y están probados (change archivado). Esta capa los expone por HTTP, entrega el token por email y completa el Flujo A/B (crear cuenta al aceptar), ahora viable porque `provision_tenant_identity` fue eliminado (crear un `User` ya no auto-crea una `Person`).

Puntos de anclaje ya implementados:
- `Accounts::InvitePerson.call(...) → Result(onboarding_request:, token:, person:)` (token en claro solo en memoria; se persiste el digest).
- `Accounts::AcceptInvitation.call(token:, organization:)` — hoy incorpora cuentas existentes y lanza `AccountRequired` cuando no hay cuenta resuelta.
- `OnboardingRequestPolicy` (invite/create/revoke → `manage_people`; assign_role → `manage_staff_assignments`; resolve_conflict → `resolve_identity_conflicts`).
- `BulkImportServices::ClassifyPeopleRow` (aditivo, aún no cableado).

## Decisiones

### D1 — Endpoints y contrato de entrada
Un controller admin de onboarding con acciones para: crear invitación/incorporación, revocar, resolver conflicto; y un endpoint (autenticado) de aceptación por token. Tenant siempre desde `Current.organization`/contexto; el cliente nunca envía `organization_id`. Cada acción `authorize`-a vía `OnboardingRequestPolicy`.

**Canal de aceptación = ambos (decidido).** El link abre una página web que, si detecta la app móvil instalada (universal link/scheme), hace deep-link a la app (auth JWT); si no, permite aceptar en web (Inertia, incluyendo fijar contraseña en Flujo A/B). ⚠️ **Dependencia externa:** requiere que la app móvil (repo aparte) soporte universal links / un scheme acordado — a coordinar antes de implementar el deep-link.

**Índice de solicitudes (decidido).** El gestor con `manage_people` puede **listar** las solicitudes pendientes de su organización y **revocarlas**; se implementa `OnboardingRequestPolicy::Scope` org-scoped (hoy devuelve `none`). Revocar lo puede hacer **cualquier** actor con `manage_people`, no solo quien emitió la invitación.

### D2 — Entrega por email
`OnboardingMailer` + job Sidekiq. El correo lleva solo un **link de un solo uso** (token en la URL, digest en BD; consumido al aceptar) con **expiración de 14 días**; **sin** datos personales sensibles, documento ni el token fuera del link. **Identifica a la organización que invita** por su nombre ("La organización X te invita a…") — auto-revelación permitida; nunca revela otras orgs del titular. i18n en `es`/`en`/`pt` (una clave por locale). `InvitePerson` ya devuelve el token en claro para que el mailer lo envíe una sola vez.

### D3 — Flujo A/B (crear cuenta al aceptar) + auto-confirmación
Ampliar `Accounts::AcceptInvitation`: cuando no hay cuenta resuelta, crear el `User` (contraseña que fija el titular) y **vincularlo explícitamente** vía `Accounts::LinkUserToPerson` + `Memberships::AcceptOnboarding`, sin hooks. **Aceptar por token auto-confirma el email (decidido):** abrir el link de un solo uso prueba posesión del correo, así que la cuenta queda `confirmed_at` al aceptar — sin segundo correo de confirmación.

### D4 — Gate de confirmación
Devise `config.allow_unconfirmed_access_for = 0` (o verificación explícita en sesión) para que un `User` no confirmado no use la app. Con D3, los invitados quedan confirmados al aceptar, por lo que el gate aplica sobre todo al **auto-registro** (cuenta creada sin pasar por un token de invitación).

### D6 — Política de contraseña
Al fijar contraseña (alta por invitación, Flujo A/B, y cualquier alta/cambio de `User`) el sistema exige **mínimo 8 caracteres con al menos una minúscula, una mayúscula, un número y un carácter especial**. Se implementa como validación en `User` (junto a Devise `:validatable`), con mensaje i18n en `es`/`en`/`pt`. Aplica de forma consistente a todos los caminos de creación/cambio de contraseña.

### D5 — Cableado del clasificador en bulk import (clasificar; el gestor decide)
`ImportPeopleRow`/validadores consultan `ClassifyPeopleRow` y **clasifican** cada fila; el import **no** envía invitaciones ni crea solicitudes automáticamente. `ready_to_create_person` crea la persona; `requires_invitation`/`requires_incorporation`/`requires_review`/`conflict` se **muestran como estado** para que el gestor dispare la acción (por fila o en lote) explícitamente; `duplicate` es idempotente; `invalid` se rechaza. Nunca se fusiona identidad. La UI de bulk import muestra el estado por fila.

### D6 — Privacidad en la UI
Las pantallas del gestor muestran solo información **neutral** (email-blind): nunca revelan si el correo ya tiene cuenta ni otras organizaciones del titular. La aceptación ocurre del lado del titular tras autenticarse.

## Risks / Trade-offs
- Creación de cuenta al aceptar toca el flujo de contraseña/confirmación de Devise; mitigar con tests de integración del endpoint de aceptación.
- Cablear el clasificador cambia el comportamiento del importador actual; usar los tests de bulk import como red y preservar la idempotencia.

## Migration Plan
Aditivo sobre lo entregado; sin migraciones destructivas. La entrega por email y los endpoints son nuevos; el cambio de comportamiento del importador se cubre con tests antes de activarlo.
