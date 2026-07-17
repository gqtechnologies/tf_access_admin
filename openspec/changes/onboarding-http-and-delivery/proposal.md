## Why

El change `normalize-user-identity-and-property-onboarding` (archivado) entregó la **columna vertebral de dominio**: identidad canónica de dos niveles, la entidad `OnboardingRequest`, `StaffAssignment` confirmable, todos los servicios canónicos (`People::ResolveIdentityMatch`/`Create`, `Accounts::InvitePerson`/`AcceptInvitation`/`LinkUserToPerson`/`ProvisionTenantIdentity`, `Memberships::*`, `IdentityConflicts::Resolve`, `BulkImportServices::ClassifyPeopleRow`), la autorización (`resolve_identity_conflicts` + `OnboardingRequestPolicy`) y la eliminación de `provision_tenant_identity`. Todo verde (suite 1118, 0 fallos).

Falta la **capa de exposición y entrega** que conecta esos servicios con la aplicación real: no hay endpoints HTTP para invitar/incorporar/aceptar, no se entrega el token por email, la aceptación que **crea una cuenta nueva** (Flujo A/B) quedó bloqueada por la auto-provisión (ya eliminada, por lo que ahora se desbloquea), el clasificador de bulk import no está cableado al pipeline ni a la UI, y falta el gate de confirmación de uso.

## What Changes

- **Endpoints HTTP de onboarding** (resto de §18): rutas + controllers + contratos de entrada para invitar/incorporar, aceptar/rechazar por token, revocar y resolver conflictos. Tenant derivado del contexto, nunca del cliente; autorización vía `OnboardingRequestPolicy`. **Índice** de solicitudes org-scoped: cualquier actor con `manage_people` lista y revoca (no solo el emisor).
- **Entrega por email del token**: mailer + i18n (`es`/`en`/`pt`) con link **de un solo uso** y **expiración de 14 días**, que **identifica a la organización que invita** por su nombre, **sin datos sensibles ni el token en claro** más allá del link.
- **Aceptación que crea cuenta nueva (Flujo A/B)**: `Accounts::AcceptInvitation` deja de lanzar `AccountRequired` y crea el `User` + vincula la `Person` explícitamente (ya viable sin `provision_tenant_identity`). **Aceptar por token auto-confirma el email** (la posesión del link lo prueba), sin segundo correo.
- **Canal de aceptación = web + móvil**: página web que hace deep-link a la app móvil si está instalada (⚠️ depende de universal links de la app móvil, repo aparte) o permite aceptar en web.
- **Gate de confirmación (§14.2)**: `User` no confirmado no accede (Devise `allow_unconfirmed_access_for = 0`); con la auto-confirmación, aplica sobre todo al auto-registro.
- **Política de contraseña**: mínimo 8 caracteres con minúscula + mayúscula + número + carácter especial, en todo camino de alta/cambio (invitación, alta admin, cambio).
- **Bulk import — clasificar; el gestor decide**: `ClassifyPeopleRow` cableado para **clasificar** cada fila y mostrar el estado en la UI; el import **no** envía invitaciones ni crea solicitudes automáticamente — el gestor las dispara explícitamente (por fila o en lote).
- **Frontend (§19)**: pantallas mínimas de invitación/incorporación con información **neutral** para el gestor (email-blind), índice de solicitudes, aceptación por link, y estados de clasificación en bulk import.
- **Auditoría (§15)** de las operaciones sensibles vía endpoints; **enumeración de tests (§20)**; verificación de specs §5/§8/§10/§11; **validación final (§22)**.

## Capabilities

### Modified Capabilities

- `property-onboarding`: añade la **entrega por email** (con nombre de la org que invita), la **creación de cuenta nueva con auto-confirmación** en la aceptación (Flujo A/B), y el **índice/revocación** de solicitudes por gestores `manage_people`.
- `bulk-import-people`: añade la **clasificación por fila** en la importación (sin auto-enviar) y su reflejo en la UI; el gestor dispara las acciones.
- `user-account-linking`: añade el **gate de confirmación** a nivel de sesión y la **política de complejidad de contraseña**.

## Impact

**Bounded context:** capa de exposición (HTTP + mailer + Vue) sobre los servicios de onboarding ya entregados. Depende del change archivado `normalize-user-identity-and-property-onboarding`.

**Backend:** nuevo `Admin::OnboardingRequestsController` (o equivalente) + rutas; `OnboardingMailer` + vistas i18n; job de entrega (Sidekiq); ampliación de `Accounts::AcceptInvitation` (creación de cuenta); integración de `ClassifyPeopleRow` en `BulkImportServices::ImportPeopleRow`/validadores; config Devise para el gate de confirmación.

**Frontend (Inertia + Vue):** páginas/paneles de invitación e incorporación (info neutral), pantalla de aceptación por token, estados de clasificación en bulk import; i18n en `es`/`en`/`pt`.

**Fuera de alcance:** rediseño de autenticación, SSO, fusión automática de personas, remediación histórica de duplicados (change separado).
