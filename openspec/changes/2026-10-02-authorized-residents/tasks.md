# Tasks

## 1. Dominio

- [x] 1.1 Estados, scopes, tipo de notificación, `AuthorizedResidentPolicy`.
- [x] 1.2 `AuthorizedResidents::Propose`, `Decide` (con push), `Withdraw`; elegibles para retirar encomiendas; verificado con `test/services/authorized_residents`.

## 2. API y admin

- [x] 2.1 API del residente y de conserjería; verificado con su test de controlador.
- [x] 2.2 Página `admin/authorized_residents`, sidebar y locales; verificado con su test, `npm run check` y `vite build`.

## 3. Validación

- [x] 3.1 Tests afectados en verde (374); `rubocop` y `brakeman` sin novedades.
- [ ] 3.2 Prueba manual: proponer desde la app, aprobar en la web, verla en conserjería y retirar una encomienda a su nombre. (Usuario)
