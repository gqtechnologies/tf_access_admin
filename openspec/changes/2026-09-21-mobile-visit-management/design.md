## Context

`Api::V1::Private::Units::VisitsController` ya expone `index` y `create` con `load_unit` + `authorize_resident!` (`Residents::VisitContext`). `Visits::Cancel` autoriza con `VisitPolicy#cancel?`, que acepta `authorize_visits` y exige estado `pending` o `authorized`. `Visits::NotifyVisitor` envía push + correo al visitante y nunca lanza excepciones.

## Goals

- Detalle, cancelación y reenvío de invitación desde la API privada, sin duplicar reglas de negocio en la app.
- Cero migraciones.

## Non-Goals

Ver `proposal.md`.

## Decisiones

### D1 — Endpoints anidados bajo la unidad

`resources :visits, only: [:index, :create, :show, :destroy]` con `member { post :resend_invitation }`, dentro de `resources :units`. Se descarta un recurso plano `/visits/:id` porque obligaría a rehacer la autorización por unidad. `before_action :load_visit, only: %i[show destroy resend_invitation]` usa `@unit.visits.includes(:visitor_person).find(params[:id])`; `RecordNotFound` ya se rescata como 404 en `BaseController`.

### D2 — `Api::Private::VisitDetailSerializer`

Atributos: `id`, `status`, `effective_status` (`effective_operational_status`), `scheduled_at`, `valid_from`, `valid_until`, `checked_in_at`, `checked_out_at`, `visitor { name, email, phone }`, `can_cancel`, `can_resend`. El documento del visitante no se expone.

- `can_cancel`: `status` en `pending`/`authorized` (misma regla que `VisitPolicy#cancellable_visit?`; la capacidad ya la garantizó `authorize_resident!`).
- `can_resend`: `Visits::ResendVisitorInvitation.resendable?(visit)` — `authorized`, no vencida y fuera del enfriamiento.

Las respuestas de `show` y de `resend_invitation` usan este serializer bajo `{ data: ... }`.

### D3 — Cancelar

`destroy` llama `Visits::Cancel.call(visit:, actor: current_user)` y responde `200 { data: { id, status } }`. `AASM::InvalidTransition` → 422 `api.visits.not_cancellable`. `Pundit::NotAuthorizedError` → 403 `api.visits.not_authorized`; como la policy mezcla estado y capacidad en `cancel?`, el controlador comprueba antes el estado y responde 422 si la visita no es cancelable, de modo que el 403 quede solo para falta de capacidad.

### D4 — `Visits::ResendVisitorInvitation`

```ruby
Visits::ResendVisitorInvitation.call(visit:, actor:)
```

- `NotResendableError` si `status != authorized` o `authorization_expired?` → 422 `api.visits.not_resendable`.
- `CooldownError` si `metadata["visitor_invitation_resent_at"]` es posterior a `COOLDOWN.ago` (`COOLDOWN = 5.minutes`) → 429 `api.visits.resend_cooldown`, con cabecera `Retry-After` en segundos.
- Si pasa: actualiza `metadata` con la marca de tiempo (merge, sin pisar otras claves), llama `Visits::NotifyVisitor.call(visit:, actor:)` y registra `RecordEvent` con `event_type: VisitEventTypes::INVITATION_RESENT` y `from_status == to_status`.
- La marca se escribe antes de notificar: un fallo de entrega (que `NotifyVisitor` absorbe) no habilita reintentos inmediatos.
- No pasa por `VisitPolicy`: la autorización es la de la unidad (`authorize_resident!`), igual que `create`. El servicio es de uso exclusivo de la API privada.

`VisitEventTypes::INVITATION_RESENT = "invitation_resent"` se añade a `ALL` (no a `MVP`). Verificar que `VisitStatusHistory` valide contra `ALL` y que las vistas del admin que pintan el historial tengan etiqueta i18n para el tipo nuevo.

### D5 — i18n

Claves nuevas en `api.visits`: `not_cancellable`, `not_resendable`, `resend_cooldown`, `not_authorized`, en `es`, `en` y `pt`. Etiqueta del evento `invitation_resent` para el historial del admin.

## Riesgos

- **Spam al visitante**: mitigado con el enfriamiento y con exigir visita `authorized` vigente.
- **Rama 3 de `NotifyVisitor`** (visitante sin cuenta): con solicitud de onboarding pendiente envía el correo sin token nuevo. Aceptable; el enlace original sigue vigente.
- **Evento con `from_status == to_status`**: confirmar que `RecordEvent` no lo rechaza.

## Testing

Solo los archivos nuevos o modificados, con `PARALLEL_WORKERS=1`:

- `test/controllers/api/v1/private/units/visits_controller_test.rb`: `show` (feliz, 401, 403, 404 de otra unidad y de otro tenant, flags), `destroy` (feliz desde `authorized` y `pending`, 422 desde `checked_in`, 403, 404), `resend_invitation` (feliz, 422 cancelada, 422 vencida, 429 con `Retry-After`, 404).
- `test/services/visits/resend_visitor_invitation_test.rb`: marca en metadata sin pisar claves, evento registrado, delega en `NotifyVisitor`, errores.
- `test/serializers/api/private/visit_detail_serializer_test.rb`: no expone documento; flags por estado.
