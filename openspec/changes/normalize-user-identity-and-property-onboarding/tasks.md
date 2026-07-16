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

- [ ] 6.1 Especificar invitación a persona sin cuenta (token, expiración, aceptación) dentro de `property-onboarding`.
  - Tests: emisión, aceptación crea/vincula `User`, expiración no concede acceso.
  - Done: ciclo de vida de invitación definido.

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

- [ ] 9.1 Especificar creación de `User` y vinculación `User`↔`Person` con confirmación del titular (`user-account-linking`).
  - Archivos: `Admin::UsersController`, `Admin::PeopleController` (`linkable_users`).
  - Tests: no crear `User` si la persona ya tiene cuenta válida; vinculación errónea bloqueada.
  - Done: reglas de vinculación y desvinculación con trazabilidad.

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

- [ ] 12.1 Especificar `IdentityConflicts::Resolve` y los 18 casos de conflicto (`identity-resolution`).
  - Comportamiento: registrar conflicto sin cambiar asociaciones; requiere resolución explícita.
  - Tests: cada caso produce el estado esperado.
  - Done: casos 1–18 cubiertos por escenarios.

## 13. Integración con bulk import

- [ ] 13.1 Especificar clasificación de filas y manejo de conflictos sin fusión automática (`bulk-import-people`).
  - Archivos: `BulkImportServices::ImportPeopleRow`, validadores de fila.
  - Tests: persona nueva/existente-sin-cuenta/existente-con-cuenta/ambigua/conflicto.
  - Done: estados de fila especificados.

## 14. Autorización

- [ ] 14.1 Especificar capacidades por actor (buscar, ver coincidencias, crear, invitar, incorporar, revocar, resolver conflictos, editar datos globales).
  - Archivos: `PersonPolicy`, `UserPolicy`, nueva `OnboardingRequestPolicy`.
  - Comportamiento: **asignar/revocar roles = solo rol manager**; gestor de propiedad no resuelve conflictos globales (`resolve_identity_conflicts`).
  - Tests: policy specs por capacidad; no-manager no asigna roles.
  - Done: matriz de autorización especificada.

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
