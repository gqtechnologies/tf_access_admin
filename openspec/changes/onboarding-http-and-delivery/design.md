## Context

Los servicios de onboarding existen y están probados (change archivado). Esta capa los expone por HTTP, entrega el token por email y completa el Flujo A/B (crear cuenta al aceptar), ahora viable porque `provision_tenant_identity` fue eliminado (crear un `User` ya no auto-crea una `Person`).

Puntos de anclaje ya implementados:
- `Accounts::InvitePerson.call(...) → Result(onboarding_request:, token:, person:)` (token en claro solo en memoria; se persiste el digest).
- `Accounts::AcceptInvitation.call(token:, organization:)` — hoy incorpora cuentas existentes y lanza `AccountRequired` cuando no hay cuenta resuelta.
- `OnboardingRequestPolicy` (invite/create/revoke → `manage_people`; assign_role → `manage_staff_assignments`; resolve_conflict → `resolve_identity_conflicts`).
- `BulkImportServices::ClassifyPeopleRow` (aditivo, aún no cableado).

## Decisiones

### D1 — Endpoints y contrato de entrada
Un controller admin de onboarding con acciones para: crear invitación/incorporación, revocar, resolver conflicto; y un endpoint público (autenticado) de aceptación por token. Tenant siempre desde `Current.organization`/contexto; el cliente nunca envía `organization_id`. Cada acción `authorize`-a vía `OnboardingRequestPolicy`.

### D2 — Entrega por email
`OnboardingMailer` + job Sidekiq. El correo lleva solo un **link de un solo uso con expiración** (token en la URL, digest en BD); **sin** datos personales sensibles, documento ni el token fuera del link. i18n en `es`/`en`/`pt` (una clave por locale). `InvitePerson` ya devuelve el token en claro para que el mailer lo envíe una sola vez.

### D3 — Flujo A/B (crear cuenta al aceptar)
Ampliar `Accounts::AcceptInvitation`: cuando no hay cuenta resuelta, crear el `User` (con contraseña que fija el titular) y **vincularlo explícitamente** vía `Accounts::LinkUserToPerson` + `Memberships::AcceptOnboarding`. No se apoya en ningún hook. El `User` recién creado queda sin confirmar hasta que confirme su email (gate D4).

### D4 — Gate de confirmación
Devise `config.allow_unconfirmed_access_for = 0` (o verificación explícita en el flujo de sesión) para que un `User` no confirmado no use la app, aunque esté vinculado/incorporado. Cubre `user-account-linking` "Unconfirmed accounts cannot use the application".

### D5 — Cableado del clasificador en bulk import
`ImportPeopleRow`/validadores consultan `ClassifyPeopleRow` y actúan por estado: `ready_to_create_person` crea; `requires_invitation`/`requires_incorporation` generan la solicitud correspondiente; `conflict`/`requires_review` no fusionan y se marcan para revisión; `duplicate` es idempotente; `invalid` se rechaza. La UI de bulk import muestra el estado por fila.

### D6 — Privacidad en la UI
Las pantallas del gestor muestran solo información **neutral** (email-blind): nunca revelan si el correo ya tiene cuenta ni otras organizaciones del titular. La aceptación ocurre del lado del titular tras autenticarse.

## Risks / Trade-offs
- Creación de cuenta al aceptar toca el flujo de contraseña/confirmación de Devise; mitigar con tests de integración del endpoint de aceptación.
- Cablear el clasificador cambia el comportamiento del importador actual; usar los tests de bulk import como red y preservar la idempotencia.

## Migration Plan
Aditivo sobre lo entregado; sin migraciones destructivas. La entrega por email y los endpoints son nuevos; el cambio de comportamiento del importador se cubre con tests antes de activarlo.
