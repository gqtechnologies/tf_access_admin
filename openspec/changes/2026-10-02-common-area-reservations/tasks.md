# Tasks

## 1. Dominio

- [x] 1.1 `ReservationStatuses`, validaciones de `CommonArea`/`CommonAreaReservation`, capacidad `manage_common_areas`, `CommonAreaPolicy`.
- [x] 1.2 `Reservations::RuleCheck`, `Request`, `Decide`, `Cancel`, `Notify` y payload de push; verificado con `test/services/reservations/*`.

## 2. API y admin

- [x] 2.1 API del residente (áreas, disponibilidad, reservas, cancelar); verificado con su test de controlador.
- [x] 2.2 Páginas `admin/common_areas` y `admin/reservations`, sidebar, locales; verificado con su test de controlador, `npm run check` y `vite build`.
- [x] 2.3 Casilla "Puede reservar áreas comunes" en ocupantes; verificado con los tests de ocupaciones y los tests JS.

## 3. Validación

- [x] 3.1 Tests afectados en verde (278); `rubocop` y `brakeman` sin novedades.
- [ ] 3.2 Prueba manual: crear un área con reglas, reservar desde la app, aprobar y rechazar en la web. (Usuario)
