## Decisiones

### D1 — `reject`

`Visit::StateMachine`: `event :reject { transitions from: :pending, to: :rejected }`. `Visits::Reject` es espejo de `Visits::Cancel` (`visit:, actor:, notes: nil`; `authorize_visit_action!(@visit, :reject?)`; `RecordEvent` con `VisitEventTypes::REJECTED`). `VisitPolicy#reject?`: misma organización, estado `pending`, y `authorize_visits` o `manage_visits`. `VisitEventTypes::REJECTED = "rejected"` se añade a `ALL`, con etiqueta i18n `frontend.admin.visits.event_types.rejected` (`es`/`en`/`pt`). Revisar que ningún scope operativo (`concierge_visible`, contadores) cuente `rejected`.

### D2 — Endpoints

En `Api::V1::Private::Units::VisitsController`, `member { post :authorize; post :reject }`; `load_visit` se extiende a ambas. El estado se comprueba antes de llamar al servicio: si no es `pending` → 422 `api.visits.not_pending` (cubre la carrera entre dos residentes de la unidad). `AASM::InvalidTransition` → mismo 422; `Pundit::NotAuthorizedError` → 403 `api.visits.not_authorized`. Respuesta `200 { data: <VisitDetailSerializer> }`. La acción se llama `authorize_visit` en el controlador para no chocar con `Pundit#authorize`, mapeada desde la ruta `authorize`.

### D3 — Aviso al visitante al autorizar

Tras `Visits::Authorize`, fuera de su transacción: `Visits::NotifyVisitor.call(visit:, actor:)` solo si `visitor_person.user.present? || visitor_person.contact_email.present?`. `NotifyVisitor` no lanza. No se usa `ResendVisitorInvitation` (no es un reenvío: no sella enfriamiento ni evento).

### D4 — Flags

`can_authorize` y `can_reject`: `object.status == pending`. La capacidad la garantiza `authorize_resident!`, igual que `can_cancel`.

### D5 — Payload del push

`Notifications::VisitRequestPushPayload#build`: `data` += `unit_id: @visit.unit_id`, `residential_property_id: @visit.residential_property_id`. FCM exige valores string en `data`; verificar que el transporte ya los convierte (el payload actual manda `visit_id` UUID) y, si no, convertir con `to_s`.

## Riesgos

- **Visita `rejected` en listados del admin**: el estado ya tiene etiqueta y es válido; confirmar que filtros por estado del admin no fallan con un valor que hasta hoy nunca aparecía.

## Testing

Solo archivos tocados, `PARALLEL_WORKERS=1`: `test/services/visits/reject_test.rb`; `test/controllers/api/v1/private/units/visits_authorization_controller_test.rb` (authorize/reject felices, 422 ya respondida, 403, 404, aviso al visitante al autorizar, sin aviso al rechazar ni sin correo, flags); test del payload existente ampliado.
