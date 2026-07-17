## Why

El change `normalize-user-identity-and-property-onboarding` (archivado) entregó la **columna vertebral de dominio**: identidad canónica de dos niveles, la entidad `OnboardingRequest`, `StaffAssignment` confirmable, todos los servicios canónicos (`People::ResolveIdentityMatch`/`Create`, `Accounts::InvitePerson`/`AcceptInvitation`/`LinkUserToPerson`/`ProvisionTenantIdentity`, `Memberships::*`, `IdentityConflicts::Resolve`, `BulkImportServices::ClassifyPeopleRow`), la autorización (`resolve_identity_conflicts` + `OnboardingRequestPolicy`) y la eliminación de `provision_tenant_identity`. Todo verde (suite 1118, 0 fallos).

Falta la **capa de exposición y entrega** que conecta esos servicios con la aplicación real: no hay endpoints HTTP para invitar/incorporar/aceptar, no se entrega el token por email, la aceptación que **crea una cuenta nueva** (Flujo A/B) quedó bloqueada por la auto-provisión (ya eliminada, por lo que ahora se desbloquea), el clasificador de bulk import no está cableado al pipeline ni a la UI, y falta el gate de confirmación de uso.

## What Changes

- **Endpoints HTTP de onboarding** (resto de §18): rutas + controllers + contratos de entrada para invitar/incorporar, aceptar/rechazar por token, revocar y resolver conflictos. Tenant derivado del contexto, nunca del cliente; autorización vía `OnboardingRequestPolicy`.
- **Entrega por email del token**: mailer + i18n (`es`/`en`/`pt`) con link de un solo uso y expiración, **sin datos sensibles ni el token en claro** más allá del link.
- **Aceptación que crea cuenta nueva (Flujo A/B)**: `Accounts::AcceptInvitation` deja de lanzar `AccountRequired` y crea el `User` + vincula la `Person` explícitamente (ya viable sin `provision_tenant_identity`); el `User` sin confirmar no puede usar la app.
- **Gate de confirmación (§14.2)**: `User` no confirmado no accede (Devise `allow_unconfirmed_access_for = 0`).
- **Cableado de `ClassifyPeopleRow`** en el pipeline de bulk import y exposición de los estados de fila en la UI de importación.
- **Frontend (§19)**: pantallas mínimas de resolución/invitación/incorporación con información **neutral** para el gestor (email-blind), aceptación por link, y estados de bulk import.
- **Auditoría (§15)** de las operaciones sensibles vía endpoints; **enumeración de tests (§20)**; verificación de specs §5/§8/§10/§11; **validación final (§22)**.

## Capabilities

### Modified Capabilities

- `property-onboarding`: añade la **entrega por email** del token y la **creación de cuenta nueva en la aceptación** (Flujo A/B), completando el ciclo ya especificado.
- `bulk-import-people`: añade la **aplicación de la clasificación** en el pipeline de importación y su reflejo en la UI.
- `user-account-linking`: añade el **contrato de los endpoints** (tenant desde contexto; el gestor nunca selecciona cuentas) a nivel HTTP.

## Impact

**Bounded context:** capa de exposición (HTTP + mailer + Vue) sobre los servicios de onboarding ya entregados. Depende del change archivado `normalize-user-identity-and-property-onboarding`.

**Backend:** nuevo `Admin::OnboardingRequestsController` (o equivalente) + rutas; `OnboardingMailer` + vistas i18n; job de entrega (Sidekiq); ampliación de `Accounts::AcceptInvitation` (creación de cuenta); integración de `ClassifyPeopleRow` en `BulkImportServices::ImportPeopleRow`/validadores; config Devise para el gate de confirmación.

**Frontend (Inertia + Vue):** páginas/paneles de invitación e incorporación (info neutral), pantalla de aceptación por token, estados de clasificación en bulk import; i18n en `es`/`en`/`pt`.

**Fuera de alcance:** rediseño de autenticación, SSO, fusión automática de personas, remediación histórica de duplicados (change separado).
