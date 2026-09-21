# Tasks

> Orden: 1 → 2 → 3 → 4. Tests solo de archivos tocados, `PARALLEL_WORKERS=1`. Mirror: `Visits::Cancel` y las acciones `destroy`/`resend_invitation` del controlador.

## 1. Rechazo (D1)

- [ ] 1.1 Evento `reject` en `Visit::StateMachine`; `VisitEventTypes::REJECTED`; etiqueta i18n del evento.
- [ ] 1.2 `VisitPolicy#reject?` y `Visits::Reject`.
- [ ] 1.3 Verificar scopes operativos y filtros del admin frente a `rejected`.
- [ ] 1.4 `test/services/visits/reject_test.rb`.

## 2. Endpoints y flags (D2, D3, D4)

- [ ] 2.1 Rutas `authorize` / `reject`; acciones con 422 `api.visits.not_pending`; i18n.
- [ ] 2.2 Aviso al visitante tras autorizar.
- [ ] 2.3 `can_authorize` / `can_reject` en `VisitDetailSerializer`.
- [ ] 2.4 Tests del controlador.

## 3. Push (D5)

- [ ] 3.1 `unit_id` y `residential_property_id` en `VisitRequestPushPayload`; test.

## 4. Cierre

- [ ] 4.1 `bundle exec rubocop` sobre lo tocado y `bundle exec brakeman`.
