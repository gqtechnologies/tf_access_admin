# Tasks

> Implementación de la capa de exposición sobre los servicios de onboarding ya entregados (change archivado `normalize-user-identity-and-property-onboarding`). Aditivo salvo el cableado del importador (con tests de red).

## 1. Endpoints HTTP de onboarding (§18)

- [ ] 1.1 Rutas + `Admin::OnboardingRequestsController` (o equivalente): crear invitación/incorporación, revocar, resolver conflicto.
  - Autorización vía `OnboardingRequestPolicy`; tenant desde contexto; strong params sin `organization_id`.
  - Tests: controller/request specs por acción y por rol (gestor no resuelve conflictos).
- [ ] 1.2 Endpoint de aceptación por token (autenticado): valida token → `Accounts::AcceptInvitation`.
  - Tests: token válido/inválido/expirado/consumido; incorporación de cuenta existente.

## 2. Entrega por email (mailer + i18n)

- [ ] 2.1 `OnboardingMailer` + vistas + job Sidekiq; link de un solo uso con expiración; sin datos sensibles ni token fuera del link.
- [ ] 2.2 i18n `es`/`en`/`pt` (una clave por locale). Tests de mailer (contenido mínimo, link presente, sin PII).

## 3. Aceptación que crea cuenta nueva (Flujo A/B)

- [ ] 3.1 Ampliar `Accounts::AcceptInvitation`: si no hay cuenta resuelta, crear `User` (contraseña del titular) + `LinkUserToPerson` + `AcceptOnboarding`. Quitar el `raise AccountRequired`.
  - Tests: aceptación crea cuenta, vincula, activa membresía; cuenta nueva sin confirmar no accede.

## 4. Gate de confirmación (§14.2)

- [ ] 4.1 Devise `allow_unconfirmed_access_for = 0` (o verificación en sesión). Tests: no confirmado bloqueado; incorporación vincula pero no da acceso.

## 5. Cableado del clasificador en bulk import (§13→§18)

- [ ] 5.1 `ImportPeopleRow`/validadores usan `ClassifyPeopleRow` y actúan por estado sin fusionar.
  - Tests: batch mixto (crear/incorporar/conflicto/duplicado/invalid) con idempotencia.
- [ ] 5.2 UI de bulk import muestra el estado por fila (i18n).

## 6. Frontend (§19)

- [ ] 6.1 Pantallas/paneles de invitación e incorporación con info **neutral** (email-blind); pantalla de aceptación por token; estados de clasificación. Vue + Inertia + i18n.

## 7. Auditoría y verificación (§15, §5/§8/§10/§11, §20, §22)

- [ ] 7.1 Auditoría de operaciones sensibles vía endpoints (actor/estado previo-posterior; sin documentos/tokens/secretos).
- [ ] 7.2 Verificar specs de decisión/aislamiento/privacidad/propiedad (§5/§8/§10/§11) contra la implementación.
- [ ] 7.3 Enumerar/cerrar cobertura de tests (§20); `openspec validate --strict` en verde (§22); `graphify update app`.
