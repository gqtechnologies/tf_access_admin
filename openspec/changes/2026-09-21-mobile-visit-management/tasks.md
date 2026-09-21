# Tasks

> Orden: 1 → 2 → 3 → 4. Cada sección termina con sus tests en verde (solo los archivos tocados, `PARALLEL_WORKERS=1`). Mirror: `Api::V1::Private::Units::VisitsController#index/create` y `Visits::Cancel`.

## 1. Detalle de visita (D1, D2)

- [ ] 1.1 Rutas: `resources :visits, only: [:index, :create, :show, :destroy]` con `member { post :resend_invitation }` bajo `namespace :private`; actualizar los comentarios del bloque.
- [ ] 1.2 `Api::Private::VisitDetailSerializer` (sin documento; `can_cancel`, `can_resend`). `can_resend` queda en `false` fijo hasta la sección 3.
- [ ] 1.3 `Units::VisitsController`: `load_visit` (`@unit.visits.includes(:visitor_person).find`) y `show`.
- [ ] 1.4 Tests de `show` y del serializer.

## 2. Cancelar (D3)

- [ ] 2.1 `destroy`: 422 previo si el estado no es cancelable; `Visits::Cancel`; rescates 422/403.
- [ ] 2.2 i18n `api.visits.not_cancellable`, `api.visits.not_authorized` (`es`/`en`/`pt`).
- [ ] 2.3 Tests de `destroy`.

## 3. Reenviar invitación (D4)

- [ ] 3.1 `VisitEventTypes::INVITATION_RESENT` en `ALL`; verificar validación de `VisitStatusHistory` y que `RecordEvent` acepte `from_status == to_status`; etiqueta i18n del evento en el historial del admin.
- [ ] 3.2 `Visits::ResendVisitorInvitation` (`resendable?`, `NotResendableError`, `CooldownError` con segundos restantes, merge de metadata, `NotifyVisitor`, `RecordEvent`).
- [ ] 3.3 `resend_invitation` en el controlador: 200 con detalle, 422, 429 + `Retry-After`. Conectar `can_resend` del serializer a `resendable?`.
- [ ] 3.4 i18n `api.visits.not_resendable`, `api.visits.resend_cooldown`.
- [ ] 3.5 Tests del servicio y del endpoint.

## 4. Cierre

- [ ] 4.1 `bundle exec rubocop` sobre los archivos tocados y `bundle exec brakeman`.
- [ ] 4.2 Actualizar la documentación de la API privada en `docs/` si lista endpoints.
