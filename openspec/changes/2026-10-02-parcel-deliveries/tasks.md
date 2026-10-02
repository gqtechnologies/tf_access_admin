# Tasks

## 1. Dominio

- [x] 1.1 `ParcelStatuses`, validaciones y scopes en `ParcelDelivery` (D1); verificar con `test/models/parcel_delivery_test.rb`.
- [x] 1.2 Capacidad `manage_parcels` en roles, presentación y locales (D2); verificar con los tests de resolver existentes y el de política.
- [x] 1.3 `Authorization::ActorContext` y `ParcelDeliveryPolicy` con `Scope` (D3); verificar con `test/policies/parcel_delivery_policy_test.rb`.

## 2. Servicios

- [x] 2.1 `Parcels::EligibleWithdrawers` (D4), `Parcels::Receive`, `Parcels::Withdraw`; verificar con `test/services/parcels/*_test.rb`.
- [x] 2.2 `Parcels::NotifyResidents` y `Notifications::ParcelPushPayload` conectados al job (D5); verificar con el test de `Receive`.

## 3. API

- [x] 3.1 `GET /units/:unit_id/parcels` (D6); verificar con su test de controlador.
- [x] 3.2 `concierge/parcels` (index, create, show, withdraw) y `concierge/units` (D7); verificar con su test de controlador.

## 4. Validación

- [x] 4.1 Tests nuevos y los tocados en verde con `PARALLEL_WORKERS=1 bin/rails test`.
- [x] 4.2 `bundle exec rubocop` sobre los archivos tocados y `bundle exec brakeman` sin advertencias nuevas.
