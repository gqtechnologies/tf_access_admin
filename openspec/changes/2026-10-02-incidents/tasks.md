# Tasks

## 1. Dominio

- [x] 1.1 `IncidentStatuses`, validaciones, capacidades `report_incidents`/`manage_incidents`, `IncidentPolicy`.
- [x] 1.2 `Incidents::Report`, `Incidents::Update` (con push) y payload; verificado con `test/services/incidents/incidents_test.rb`.

## 2. API y admin

- [x] 2.1 API del reportante (index, create); verificado con su test de controlador.
- [x] 2.2 Página `admin/incidents` con drawer, sidebar y locales; verificado con su test de controlador, `npm run check` y `vite build`.

## 3. Validación

- [x] 3.1 Tests afectados en verde; `rubocop` y `brakeman` sin novedades.
- [ ] 3.2 Prueba manual: reportar desde la app, gestionar y cerrar en la web, recibir el push. (Usuario)
