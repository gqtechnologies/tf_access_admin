# Tasks

> Implementación de la capa de exposición sobre los servicios de onboarding ya entregados (change archivado `normalize-user-identity-and-property-onboarding`). Aditivo salvo el cableado del importador (con tests de red).

## 1. Endpoints HTTP de onboarding (§18)

- [x] 1.1 Rutas + `Admin::OnboardingRequestsController`: `index`/`new`/`create` (invita vía `Accounts::InvitePerson` + entrega email), `revoke`, `resolve_conflict`. Autorización `OnboardingRequestPolicy`; tenant desde contexto. Backend testeado; falta la UI (§6).
  - Tests: `onboarding_requests_controller_test.rb` (index, create+email encolado, no-manager bloqueado). 3/3.
- [x] 1.2 `OnboardingAcceptancesController` (`get/post onboarding/accept/:token`): resuelve org por token, muestra info neutral (org + email enmascarado), acepta vía `Accounts::AcceptInvitation`.
  - Tests: `onboarding_acceptances_controller_test.rb` (show neutral, token inválido, aceptación crea cuenta confirmada + membresía activa). 3/3.
- [~] 1.3 `OnboardingRequestPolicy::Scope` org-scoped implementado: devuelve las solicitudes de la org solo si el actor tiene `manage_people`, si no `none`. ✅ (`onboarding_request_policy_test.rb`, 4/4).
  - **Pendiente (con 1.1):** la acción `index` HTTP que consume el scope + la UI.

## 2. Entrega por email (mailer + i18n)

- [x] 2.1 `OnboardingMailer#invitation` + vistas html/text; `deliver_later` (Sidekiq) desde el controller; link de un solo uso (`onboarding_acceptance_url`), nombre de la org, sin PII.
- [x] 2.2 i18n `onboarding_mailer.invitation.*` en es/en/pt. Test: `onboarding_mailer_test.rb` (org en asunto/cuerpo, link presente, sin documento). 1/1.

## 3. Aceptación que crea cuenta nueva (Flujo A/B)

- [x] 3.1 `Accounts::AcceptInvitation` ampliado: sin cuenta resuelta crea `User` (password del titular + name/dni/language con fallback a datos de la `Person`, `skip_confirmation!`) + `LinkUserToPerson` + `AcceptOnboarding`; **auto-confirma el email** en ambos ramos (existente sin confirmar también). `AccountRequired` ahora exige password.
  - Tests: `invitation_test.rb` (9/9) — Flujo A/B crea cuenta confirmada+vinculada+membresía activa; incorporación; single-use/inválido/expirado.

## 4. Gate de confirmación (§14.2)

- [x] 4.1 `config.allow_unconfirmed_access_for = 0.days` en `config/initializers/devise.rb` (sin periodo de gracia). Con auto-confirmación al aceptar (D3), el gate aplica sobre todo al auto-registro.
  - Tests: `test/models/user_confirmation_gate_test.rb` — no confirmado no `active_for_authentication?`; confirmado sí. Suite completa 1128, 0 fallos.

## 4b. Política de contraseña (D6)

- [x] 4b.1 Validación `User#password_meets_complexity` (`PASSWORD_COMPLEXITY`): min 8 + minúscula + mayúscula + dígito + símbolo `[$%@.\-_]`; mensaje `admin.users.validations.password_complexity` en es/en/pt. Frontend Zod (`schemas/user.ts`) alineado: **añadido el dígito** que faltaba (`password_number`). Migrados los tests (`password1` → `Password1@`).
  - Tests: `test/models/user_password_policy_test.rb` (7/7); suite completa 1118, 0 fallos; type-check sin errores nuevos.

## 5. Cableado del clasificador en bulk import (§13→§18)

- [ ] 5.1 `ImportPeopleRow`/validadores usan `ClassifyPeopleRow` para **clasificar**: crear solo las filas `ready_to_create_person`; el resto (invitación/incorporación/revisión/conflicto) se registra con su estado para que **el gestor** dispare la acción; `duplicate` idempotente; `invalid` rechazada. **No** auto-envía invitaciones ni crea solicitudes.
  - Tests: batch mixto (crear/incorporar/conflicto/duplicado/invalid); no se auto-envían correos; idempotencia.
- [ ] 5.2 UI de bulk import muestra el estado por fila (i18n).

## 6. Frontend (§19)

- [ ] 6.1 Pantallas/paneles de invitación e incorporación con info **neutral** (email-blind); pantalla de aceptación por token; estados de clasificación. Vue + Inertia + i18n.

## 7. Auditoría y verificación (§15, §5/§8/§10/§11, §20, §22)

- [ ] 7.1 Auditoría de operaciones sensibles vía endpoints (actor/estado previo-posterior; sin documentos/tokens/secretos).
- [ ] 7.2 Verificar specs de decisión/aislamiento/privacidad/propiedad (§5/§8/§10/§11) contra la implementación.
- [ ] 7.3 Enumerar/cerrar cobertura de tests (§20); `openspec validate --strict` en verde (§22); `graphify update app`.
