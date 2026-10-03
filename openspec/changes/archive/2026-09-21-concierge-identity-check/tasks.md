# Tasks

- [x] 1. Serializer: `visitor.avatar_url`, `can_check_in` exige foto; precarga en el listado.
- [x] 2. `check_in` sin parámetros y 422 `photo_required`.
- [x] 3. `VisitEventTypes::ENTRY_DENIED`, `NotificationTypes::VISIT_ENTRY_DENIED`, `Visits::DenyEntry`, payload, mapa de payloads en el job, i18n `es`/`en`/`pt`.
- [x] 4. Ruta y acción `deny_entry` (200 / 422 / 429 / 403 / 404).
- [x] 5. Tests (el servicio `Visits::DenyEntry` se cubre desde los tests del endpoint) y `rubocop` / `brakeman` sobre lo tocado.
- [x] 6. Seeds: `SEED_VISITOR_PHOTO` opcional para la foto del visitante de prueba; aviso en la salida si queda sin foto.
