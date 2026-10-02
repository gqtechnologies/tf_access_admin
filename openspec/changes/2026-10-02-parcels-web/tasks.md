# Tasks

## 1. Permiso de retiro (D4)

- [x] 1.1 `can_withdraw_parcels` en parámetros, `UnitOccupancies::Mutation`/`Update`, serializer y auditoría; verificado con el test del controlador de ocupaciones.
- [x] 1.2 Checkbox en alta/edición, fila en la confirmación y columna en la tabla de ocupantes; verificado con `npm run check` y los tests JS de los drawers.

## 2. Conserjería web (D1, D2, D3)

- [x] 2.1 `Concierge::ParcelsController` (index, create, withdraw) y rutas; verificado con `test/controllers/concierge/parcels_controller_test.rb`.
- [x] 2.2 Página `concierge/parcels/index`, drawers de llegada y retiro, composable y tipos; verificado con `npm run check` y `vite build`.
- [x] 2.3 Enlace en el sidebar y `manage_parcels` en los tipos de capacidades.
- [x] 2.4 Textos `es`/`en`/`pt`.

## 3. Validación

- [x] 3.1 Tests tocados en verde con `PARALLEL_WORKERS=1 bin/rails test`; `bundle exec rubocop` y `bundle exec brakeman` sin novedades.
- [ ] 3.2 Prueba manual en el navegador: activar el permiso a un ocupante, registrar una llegada y un retiro. (Usuario)
