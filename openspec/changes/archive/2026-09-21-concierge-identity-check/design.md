## Decisiones

### D1 — Foto del visitante
`Api::Private::ConciergeVisitSerializer#visitor` → `{ name, avatar_url }`, con `avatar_url = visitor_person.user&.avatar_path` (nil sin cuenta o sin foto). `can_check_in` exige además `avatar_url` presente. El listado precarga `visitor_person: { user: { avatar_attachment: :blob } }`.

### D2 — Ingreso
`check_in` no acepta parámetros. Sin foto → 422 `api.concierge.photo_required` antes de llamar a `Visits::CheckIn`.

### D3 — `Visits::DenyEntry`
`call(visit:, actor:)`. Autoriza con `VisitPolicy#check_in?` (quien puede dejar pasar puede denegar). Exige visita `authorized` → si no, `NotDeniableError` (422 `api.concierge.invalid_transition`). Enfriamiento de 5 min en `metadata["entry_denied_at"]` con `update_column` (misma razón que `ResendVisitorInvitation`) → `CooldownError` (429 + `Retry-After`). Registra `RecordEvent` `entry_denied` con `from_status == to_status`. Fuera de la transacción crea una `Notification` `visit_entry_denied` para la persona del anfitrión y encola `DeliverPushNotificationJob`. Anfitrión = `authorized_by || created_by`; sin anfitrión o sin `Person` en la organización → solo el evento. El estado de la visita no cambia.

### D4 — Push
`Notifications::VisitEntryDeniedPushPayload`: textos en el idioma del destinatario; `data` = `type`, `visit_id`, `unit_id`, `residential_property_id`, `visitor_name` (las mismas claves de navegación que `visit_request`). `DeliverPushNotificationJob#payload_builder_for` pasa a un mapa por tipo. El agregado `notification_status` de la visita sigue considerando solo `visit_request`.

## Testing
Casos nuevos en `concierge/visits_controller_test.rb` (avatar_url, foto obligatoria, deny_entry feliz/429/422/404/403); `visit_entry_denied_push_payload_test.rb`.
