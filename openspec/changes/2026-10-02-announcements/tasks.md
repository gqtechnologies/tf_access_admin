# Tasks

## 1. Dominio

- [x] 1.1 `AnnouncementStatuses`, validaciones y scope `visible`; capacidad `manage_announcements` con presentación y locales.
- [x] 1.2 `AnnouncementPolicy`, `Announcements::Publish` (push a la propiedad) y `Announcements::Archive`; verificado con `test/services/announcements/publish_test.rb`.

## 2. API y admin

- [x] 2.1 API del residente (index, show, acknowledge); verificado con su test de controlador.
- [x] 2.2 `Admin::AnnouncementsController`, página Inertia con drawer y confirmación, sidebar y locales `es`/`en`/`pt`; verificado con su test de controlador, `npm run check` y `vite build`.

## 3. Validación

- [x] 3.1 Tests existentes afectados (autorización, roles, job de push, encomiendas) en verde; `rubocop` y `brakeman` sin novedades.
- [ ] 3.2 Prueba manual: publicar un aviso en la web y verlo llegar al teléfono. (Usuario)
