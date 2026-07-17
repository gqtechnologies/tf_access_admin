# Tasks

> Este change **define contrato** (specs/design). Las tareas de implementación quedan sin marcar; la implementación de código está fuera del alcance de este paso.

## 1. Análisis del modelo actual

- [ ] 1.1 Documentar cardinalidad real `Person`↔`User`↔`OrganizationMembership`↔`StaffAssignment`↔`UnitOwnership`↔`UnitOccupancy`.
  - Archivos: `app/models/{person,user,organization_membership,staff_assignment,unit_ownership,unit_occupancy}.rb`.
  - Comportamiento esperado: mapa de asociaciones e índices únicos actuales.
  - Evidencia: tabla de cardinalidad + índices parciales existentes.
  - Tests: n/a (análisis).
  - Done: `person-identity` refleja el modelo real.

## 2. Inventario de flujos de creación e invitación

- [ ] 2.1 Inventariar puntos de creación/vinculación de `Person`/`User`: `User#provision_tenant_identity`, `Admin::UsersController#create`, `Admin::PeopleController#{create,update}`, `BulkImportServices::ImportPeopleRow`.
  - Evidencia: lista de flujos y su comportamiento actual (auto-provisión, sin dedupe, `linkable_users` no cableado).
  - Done: cada flujo tiene un requisito o nota de reemplazo.

## 3. Definición de identidad canónica

- [ ] 3.1 Especificar modelo de dos niveles y datos globales vs contextuales (`person-identity`).
  - Comportamiento: `User` global; `Person` por organización; autoridad de actualización.
  - Tests requeridos: modelo `Person`/`User` — cardinalidad, datos contextuales aislados.
  - Done: requisitos `SHALL` con escenarios `GIVEN/WHEN/THEN`.

## 4. Reglas de búsqueda y coincidencia

- [x] 4.1 `People::ResolveIdentityMatch` implementado (`app/services/people/resolve_identity_match.rb`): servicio **aditivo** (no toca `FindExisting` ni sus 5 callers). Devuelve `Result` tipado (`none`/`matched_person`/`matched_account`/`conflict`): correo = clave de cuenta (server-side, con/sin confirmar), documento = clave de persona por org, señales débiles no son inputs, conflicto `email_belongs_to_other_account` sin cambiar asociaciones.
  - Tests: `test/services/people/resolve_identity_match_test.rb` (none, person por documento, matched_account, person del usuario en org, conflicto, metadata email, aislamiento tenant). ✅ 7/7.
  - **Pendiente:** migrar los callers de `FindExisting` a este servicio y ampliar casos de conflicto (→ §12 `IdentityConflicts::Resolve`).

## 5. Prevención de mezcla de identidades

- [ ] 5.1 Especificar cuándo se vincula automáticamente, se pide confirmación, se requiere revisión o se rechaza (`identity-resolution`).
  - Comportamiento: sin fusión por solo nombre/teléfono/email.
  - Tests: cada nivel de confianza produce la decisión correcta.
  - Done: matriz de decisión especificada.

## 6. Diseño de invitaciones

- [x] 6.1 Invitación de cuenta con token implementada (`app/services/accounts/{invite_person,accept_invitation}.rb`, `app/services/people/create.rb`):
  - `Accounts::InvitePerson` — resuelve identidad (conflicto→sin token; matched_person→reutiliza; matched_account→crea Person + referencia cuenta; none→crea Person), emite `OnboardingRequest` pendiente con **token de un solo uso** (solo se persiste el digest SHA-256); devuelve el token para el mailer.
  - `Accounts::AcceptInvitation` — verifica digest + expiración + estado pendiente (posesión del link no basta), consume el token (un solo uso), y para **cuenta existente** (Flujo C) vincula e incorpora vía `LinkUserToPerson` + `AcceptOnboarding`.
  - Tests: `test/services/accounts/invitation_test.rb` (emisión, digest no-plano, incorporación, single-use, token inválido, expirado, cuenta-requerida). ✅ 9/9.
  - **Pendiente/diferido:** aceptación que **crea cuenta nueva** (Flujo A/B) → depende de retirar `provision_tenant_identity` (§18/§21); entrega por **email** (mailer + i18n es/en/pt).

## 7. Diseño de solicitudes de incorporación

- [x] 7.1 `OnboardingRequest` (modelo + migración) creado (`app/models/onboarding_request.rb`, `db/migrate/20260716000001_create_onboarding_requests.rb`): campos, estados AASM (pending/accepted/rejected/expired/revoked/conflict), `acts_as_tenant`, `acts_as_paranoid`, `audited`, token digest único, índice parcial de pendientes.
  - Comportamiento: un concepto cubre invitación e incorporación; `user_id` opcional distingue caso.
  - **Pendiente (servicios §17):** la **idempotencia total** de solicitudes pendientes se enforce en el servicio, no solo en la BD — el índice parcial no bloquea el caso membership sin `residential_property_id`/`unit_id` porque Postgres trata los NULL como distintos. Test `onboarding_request_test.rb` fija esa frontera.
  - Tests: creación, tenant scoping, transiciones AASM, unicidad de token, frontera de idempotencia NULL. ✅

## 8. Membresías multi-organización

- [ ] 8.1 Especificar participación en múltiples organizaciones con permisos e información aislados (`organization-membership`).
  - Tests: revocar en O1 no afecta O2; permisos por org independientes.
  - Done: aislamiento multi-tenant especificado.

## 9. Vinculación entre Person y User

- [~] 9.1 Vinculación `User`↔`Person` implementada como primitivo (`app/services/accounts/link_user_to_person.rb`): guardas de cardinalidad (persona↔≤1 user; user↔≤1 person/org), idempotente, auditada vía `Person.user_id`. Desvinculación en `Memberships::Revoke(unlink_user:)`. Aceptación por titular vía `AcceptInvitation`/`AcceptOnboarding`.
  - Tests: vinculación, idempotencia, conflicto (persona ya vinculada) en `onboarding_lifecycle_test.rb`.
  - **Pendiente (§18):** repuntar `Admin::UsersController`/`Admin::PeopleController` (quitar `linkable_users` que expone emails) a estos servicios.

## 10. Integración con propiedades y unidades

- [ ] 10.1 Especificar que crear cuenta / incorporar no crea automáticamente `UnitOwnership`/`UnitOccupancy`/`StaffAssignment` (`person-identity`, `property-onboarding`).
  - Tests: incorporación no crea relaciones con unidades; relaciones siguen independientes.
  - Done: separación garantizada en requisitos.

## 11. Privacidad entre organizaciones

- [ ] 11.1 Especificar contrato de privacidad neutral cross-tenant (`identity-resolution`).
  - Comportamiento: respuestas neutrales; sin fuga de datos de otra org.
  - Tests: resolución con persona en otra org no revela nombre/propiedades/roles/emails.
  - Done: contrato de privacidad exacto especificado.

## 12. Manejo de conflictos

- [~] 12.1 `IdentityConflicts::Resolve` implementado (`app/services/identity_conflicts/resolve.rb`): resuelve un `OnboardingRequest` en conflicto con decisión explícita — `dismiss` (revoca, sin cambiar asociaciones) o `link` (vinculación manual verificada + revoca), con sello de auditoría (`resolution` en metadata). El registro del conflicto sin cambiar asociaciones ya lo hace `People::ResolveIdentityMatch` + `RequestOnboarding`/`InvitePerson`.
  - Tests: `test/services/identity_conflicts/resolve_test.rb` (dismiss, link, link sin target, no-conflicto). ✅ 4/4.
  - **Pendiente:** cablear la capacidad `resolve_identity_conflicts` en `Authorization::Capabilities`/policy (→ §14, con cuidado del ripple en `ORGANIZATION_ADMIN`/contadores de `operational_roles`); ampliar cobertura de los 18 casos como escenarios (varios ya cubiertos en `resolve_identity_match_test`).

## 13. Integración con bulk import

- [~] 13.1 `BulkImportServices::ClassifyPeopleRow` implementado (`app/services/bulk_import_services/classify_people_row.rb`): clasifica cada fila vía `ResolveIdentityMatch` sin fusionar — `ready_to_create_person` / `requires_invitation` (persona sin cuenta) / `requires_incorporation` (cuenta existente sin persona en org, o persona con cuenta) / `conflict` / `duplicate` (membresía activa o request pendiente) / `invalid` (sin email ni documento).
  - Tests: `test/services/bulk_import_services/classify_people_row_test.rb` (7/7). ✅
  - **Pendiente (§18):** cablear el clasificador en el pipeline (`ImportPeopleRow`/validadores) — no toca el importador actual todavía.

## 14. Autorización

- [x] 14.1 Autorización implementada:
  - Capacidad dedicada `Authorization::Capabilities::RESOLVE_IDENTITY_CONFLICTS`, añadida a `ALL` pero **excluida de `ORGANIZATION_ADMIN`**; `GrantProfile` la otorga **solo a super_admin** (tenant_admin no la obtiene) — honra "por defecto super_admin, delegable".
  - `OnboardingRequestPolicy`: invitar/crear/revocar → `manage_people`; asignar rol operativo → `manage_staff_assignments` (rol manager); resolver conflicto → `resolve_identity_conflicts`.
  - Tests: `test/policies/onboarding_request_policy_test.rb` — tenant_admin **no** resuelve conflictos; content_manager **no** asigna roles; client nada. ✅ 3/3.
  - Suite completa **1118 runs, 0 fallos** (sin regresión por el cambio de catálogo).

- [ ] 14.2 Gate de confirmación: `User` no confirmado no puede usar la app (Devise `:confirmable`, `allow_unconfirmed_access_for = 0`), aunque esté vinculado/incorporado.
  - Tests: usuario no confirmado bloqueado; incorporación de cuenta no confirmada vincula pero no da acceso.
  - Done: gate especificado y cubierto.

## 15. Auditoría

- [ ] 15.1 Especificar auditoría de operaciones sensibles sin persistir documentos/tokens/secretos.
  - Tests: cada operación sensible genera registro con actor/estado previo-posterior.
  - Done: campos de auditoría definidos.

## 16. Restricciones de base de datos

- [x] 16.1 Restricciones verificadas/creadas: nueva unicidad parcial de solicitudes pendientes + token digest (`onboarding_requests`); confirmadas existentes sin cambios (`people` únicas `(organization_id,user_id)` y `(organization_id,document_type,document_number_digest)`; `users.email` global; `organization_memberships` activo/invitado parcial).
  - **Salvedad documentada:** la unicidad de pendientes en BD es best-effort (NULLs distintos en Postgres); la idempotencia total va en el servicio (§7/§17).
  - Tests: unicidad de token rechazada; frontera NULL fijada en `onboarding_request_test.rb`. ✅

- [x] 16.2 `StaffAssignment` con `confirmation_state` (default `confirmed`) + `confirmed_at` migrados; modelo con validación, scopes `confirmed`/`pending_confirmation`, `confirm!`.
  - Archivos: `db/migrate/20260716000002_add_confirmation_to_staff_assignments.rb`, `app/models/staff_assignment.rb`, `test/models/staff_assignment_test.rb`.
  - **Pendiente (deferido a §17):** enforcement en `Authorization::Resolver` para derivar solo roles operativos **confirmados**. Hoy la columna es inerte (aditivo, no rompe comportamiento actual).
  - Tests: default confirmed, `confirm!` sella `confirmed_at`, scopes particionan. ✅

## 17. Servicios canónicos

- [x] 17.1 Servicios de ciclo de onboarding implementados (aditivos, responsabilidad única):
  - `Accounts::LinkUserToPerson` — primitivo con guardas de cardinalidad (persona↔≤1 user, user↔≤1 person/org), idempotente, sin tocar unidades.
  - `Memberships::RequestOnboarding` — resuelve identidad (`ResolveIdentityMatch`), registra conflicto sin cambiar asociaciones, idempotente, aplica regla de activación: **cliente** → membresía activa + rol + request aceptada; **operativo** → request pendiente + `StaffAssignment` sin confirmar.
  - `Memberships::AcceptOnboarding` — activa membresía, vincula cuenta, confirma rol operativo.
  - `Memberships::RejectOnboarding` — rechaza y desactiva rol operativo pendiente.
  - `Memberships::Revoke` — revoca membresía org-scoped; `unlink_user:` desvincula (declinar cliente) conservando `Person` + unidades.
  - Tests: `test/services/memberships/onboarding_lifecycle_test.rb` (9/9) + `resolve_identity_match_test.rb` (7/7).
  - **Pendiente:** `People::Create` + `Accounts::InvitePerson` (persona nueva / invitación por email), `IdentityConflicts::Resolve` (§12), y ampliar relationships (ownership/occupancy/property_access).

## 18. Controllers y contratos de entrada

- [ ] 18.1 Especificar endpoints y strong params; tenant derivado del contexto, no del cliente.
  - Done: contratos de entrada definidos.

## 19. Flujos frontend

- [ ] 19.1 Especificar pantallas mínimas de resolución/invitación/incorporación con información neutral para el gestor.
  - Done: props mínimas y estados de UI definidos (sin duplicar reglas de negocio en Vue).

## 20. Tests

- [ ] 20.1 Enumerar cobertura requerida: modelos, servicios, policies, controllers, bulk import, privacidad, conflictos, idempotencia, expiración.
  - Done: plan de tests por capacidad.

## 21. Migración y compatibilidad

- [ ] 21.1 **Eliminar `provision_tenant_identity`** — ⚠️ **BLOCKED-BY §17 (servicios) + §18 (controllers).** NO borrar el método en aislamiento: `Admin::UsersController#create`, el registro y muchos tests/fixtures dependen de la auto-provisión. Borrarlo antes rompe la creación de usuarios y la suite.
  - **Receta de transición no-rompiente (verde en cada commit):**
    1. §17: construir los servicios de onboarding que crean `Person`/membresía/rol explícitamente.
    2. §18: repuntar `Admin::UsersController#create` + registro a esos servicios.
    3. Volver `provision_tenant_identity` **no-op / guardado** (no borrar aún).
    4. Migrar tests/fixtures que asumen auto-`Person` (p.ej. `create_person_in_org` en `staff_assignment_test.rb`/`onboarding_request_test.rb` usa `User.create! → person_for`).
    5. **Recién entonces** eliminar el método. Nunca un `git rm` directo.
  - Comportamiento objetivo: `User` sin `Person` es estado válido; `Person`/membresía/rol solo vía onboarding.
  - Grandfathering: cuentas existentes con `Person`+membresía se conservan; no se borran datos. Remediación histórica (duplicados, dos `User` por humano) diferida a change separado.

## 22. Validación final de OpenSpec

- [ ] 22.1 `openspec validate normalize-user-identity-and-property-onboarding --strict` en verde.
  - Done: change válido.
