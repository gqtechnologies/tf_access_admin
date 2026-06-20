## 1. Modelo, migraciones y asociaciones

* [x] 1.1 Evolucionar `visits` con contexto territorial, personas, actores `User`, fechas, estado, notas y `metadata`
* [x] 1.2 Migrar nombres/valores legacy y backfill de propiedad/sección desde unidad
* [x] 1.3 Asociar `Visit` a organización, propiedad, sección, unidad, visitante, anfitrión y actores
* [x] 1.4 Validar coherencia tenant/location, fechas y elegibilidad activa del anfitrión
* [x] 1.5 Definir estados y tipos MVP, índices y estrategia de tablas legacy
* [x] 1.6 Formalizar estructura de metadata MVP para vehículo opcional y datos operativos de ingreso/salida
* [x] 1.7 Añadir tests de validación y round-trip de metadata permitida

## 2. Estados AASM y auditoría técnica

* [x] 2.1 Integrar AASM con `pending`, `authorized`, `checked_in`, `checked_out`, `cancelled`
* [x] 2.2 Implementar eventos `authorize`, `check_in`, `check_out`, `cancel`
* [x] 2.3 Restringir check-in a `authorized`, check-out a `checked_in` y cancelación a `pending`/`authorized`
* [x] 2.4 Resolver estado inicial en backend según capability, sin confiar en el frontend
* [x] 2.5 Registrar actores `User` y timestamps de autorización, ingreso y salida
* [x] 2.6 Mantener `audited` como auditoría técnica
* [x] 2.7 Revalidar tests de transiciones inválidas: no cancelar `checked_in`/`checked_out`, no check-in fuera de `authorized`, no check-out fuera de `checked_in`

## 3. Historial funcional

* [ ] 3.1 Evolucionar `visit_status_histories` o crear `visit_events` con `visit_id`, `organization_id`, `event_type`, `from_status`, `to_status`, `actor_user_id`, `occurred_at`, `notes`, `metadata`
* [ ] 3.2 Registrar evento `created` en `Visits::Create`
* [ ] 3.3 Registrar eventos `authorized`, `checked_in`, `checked_out`, `cancelled` en la misma transacción de cada servicio
* [ ] 3.4 Exponer asociaciones/scopes tenant-safe y orden cronológico
* [ ] 3.5 Crear serializer de eventos/historial para timeline y panel de actores
* [ ] 3.6 Testear contenido, actor, timestamps, metadata y rollback atómico del historial funcional

## 4. Servicios de dominio

* [ ] 4.1 Implementar `Visits::Create` con denormalización, visitante `Person`, anfitrión elegible y actor
* [ ] 4.2 Implementar `Visits::Authorize`
* [ ] 4.3 Implementar `Visits::CheckIn`
* [ ] 4.4 Implementar `Visits::CheckOut`
* [ ] 4.5 Implementar `Visits::Cancel`
* [ ] 4.6 Autorizar servicios vía Pundit y usar transacciones atómicas
* [ ] 4.7 Eliminar cualquier permiso o rama que permita a conserjería crear visitas no planificadas
* [ ] 4.8 Extender `Visits::CheckIn` con `access_point`, `access_type`, `vehicle_plate` y `notes`
* [ ] 4.9 Extender `Visits::CheckOut` con `access_point`, `incident_type` y `notes`
* [ ] 4.10 Validar/normalizar metadata operacional y preservar solo claves permitidas
* [ ] 4.11 Testear servicios con metadata, historial funcional, estado inicial backend y denegación de creación por conserjería

## 5. Policies y scopes

* [ ] 5.1 Implementar `VisitPolicy#index?`, `show?`, `create?`, `update?`, `authorize?`, `cancel?`, `check_in?`, `check_out?`
* [ ] 5.2 Alinear policy con `manage_visits`, `create_visits`, `authorize_visits`, `view_authorized_visits`, `register_visit_entry`, `register_visit_exit`
* [ ] 5.3 Scope tenant_admin organization-wide y property_admin por propiedades asignadas
* [ ] 5.4 Scope resident/owner por unidades y capabilities contextuales
* [ ] 5.5 Ajustar scope concierge a propiedades asignadas y solo `authorized`, `checked_in`, `checked_out` recientes
* [ ] 5.6 Denegar explícitamente a conserjería `create?`, `update?`, `authorize?` y `cancel?`
* [ ] 5.7 Permitir `show?` completo con `manage_visits` y restringido con `view_authorized_visits`
* [ ] 5.8 Limitar `cancel?` a estados `pending`/`authorized` y alcance administrativo/contextual permitido
* [ ] 5.9 Mantener check-in/check-out fuera de administración salvo capability operativa explícita
* [ ] 5.10 Testear scopes/actions por rol, estado, propiedad y organización

## 6. Controllers y endpoints

* [ ] 6.1 Crear rutas/controller para index, show, create, authorize, check-in, check-out y cancel
* [ ] 6.2 Definir strong params y respuestas Inertia iniciales
* [ ] 6.3 Añadir/update endpoint administrativo de edición cuando el estado sea editable
* [ ] 6.4 Separar endpoints o modos de respuesta para listado administrativo y listado operativo
* [ ] 6.5 Aceptar y validar payloads de metadata de check-in/check-out
* [ ] 6.6 Devolver errores de policy, transición y validación consumibles por Inertia
* [ ] 6.7 Refrescar listado, contadores y detalle tras acciones operativas
* [ ] 6.8 Testear requests/controllers, incluyendo 403 cross-org/cross-property

## 7. Serializers y props Inertia

* [x] 7.1 Crear serializer administrativo base con `permissions`
* [x] 7.2 Crear serializer mínimo base para conserjería
* [ ] 7.3 Crear/ajustar serializer de listado operativo
* [ ] 7.4 Crear/ajustar serializer de listado administrativo
* [ ] 7.5 Crear serializer de detalle completo
* [ ] 7.6 Crear serializer de detalle restringido
* [ ] 7.7 Crear serializer resumen para check-in/check-out
* [ ] 7.8 Integrar serializer de eventos/historial
* [ ] 7.9 Exponer `permissions`/`actions` por visita calculadas en backend
* [ ] 7.10 Exponer contadores `authorized`, `checked_in`, `recent_checked_out`, filtros y propiedad asignada
* [ ] 7.11 Testear ausencia de datos administrativos en payload restringido y consistencia de acciones

## 8. UI: Concierge Authorized Visits

* [ ] 8.1 Crear página operativa basada en [`mockups/visits_lists_property.png`](mockups/visits_lists_property.png)
* [ ] 8.2 Mostrar propiedad asignada y tabs Autorizadas, Ingresadas, Salidas recientes
* [ ] 8.3 Implementar búsqueda por visitante, unidad o anfitrión y filtros operativos
* [ ] 8.4 Crear tabla paginada con columnas operativas y badges de estado
* [ ] 8.5 Crear `VisitActionsDropdown` y eliminar botones inline de acciones
* [ ] 8.6 Mapear acciones backend: `authorized` view/check-in; `checked_in` view/check-out; `checked_out` reciente view
* [ ] 8.7 Ocultar creación, edición, autorización y cancelación para conserjería
* [ ] 8.8 Añadir navegación sidebar con `view_authorized_visits`
* [ ] 8.9 Refrescar tabs, contadores y filas tras check-in/check-out

## 9. UI: Check-in y Check-out

* [ ] 9.1 Crear modal/drawer de check-in basado en [`mockups/visit_checkin.png`](mockups/visit_checkin.png)
* [ ] 9.2 Mostrar resumen, estado, unidad, anfitrión, horario autorizado y campos operativos
* [ ] 9.3 Conectar Confirmar ingreso con `Visits::CheckIn`, errores y estado loading
* [ ] 9.4 Crear modal/drawer de check-out basado en [`mockups/visit_checkout.png`](mockups/visit_checkout.png)
* [ ] 9.5 Mostrar resumen, ingreso registrado, salida, acceso, observaciones, incidencia y timeline
* [ ] 9.6 Conectar Confirmar salida con `Visits::CheckOut`, errores y estado loading
* [ ] 9.7 Mantener acciones de apertura dentro de `VisitActionsDropdown`
* [ ] 9.8 Verificación manual: conserjería solo opera visitas válidas de su propiedad

## 10. UI: Admin Visits Management

* [ ] 10.1 Crear listado administrativo basado en [`mockups/visits_organization.png`](mockups/visits_organization.png)
* [ ] 10.2 Implementar alcance organización completa / propiedad asignada cuando aplique
* [ ] 10.3 Añadir filtros de propiedad, unidad, estado, fechas y búsqueda
* [ ] 10.4 Crear tabla paginada con columnas administrativas
* [ ] 10.5 Mostrar Nueva visita solo con permission backend
* [ ] 10.6 Usar `VisitActionsDropdown` para todas las acciones de fila
* [ ] 10.7 Mapear acciones administrativas por estado y `permissions`
* [ ] 10.8 Mostrar check-in/check-out solo con capability operativa explícita
* [ ] 10.9 Verificación manual tenant_admin organization-wide y property_admin solo asignadas

## 11. UI: Visit Create

* [x] 11.1 Crear flujo administrativo multi-paso de propiedad, unidad, visitante, anfitrión, horario y confirmación
* [x] 11.2 Filtrar unidades por propiedad y anfitriones por relación activa
* [x] 11.3 Buscar/crear visitante `Person`
* [x] 11.4 Manejar loading, empty, success y error con footer `justify-between`
* [ ] 11.5 Alinear stepper a Información general, Visitante, Fecha/horario, Adicional, Notas/confirmación
* [ ] 11.6 Añadir documento, teléfono, motivo, vehículo opcional y notas al contrato de formulario
* [ ] 11.7 Implementar `VisitAuthorizationSummary` basado en [`mockups/visit_create.png`](mockups/visit_create.png)
* [ ] 11.8 Asegurar que el resumen no persiste ni decide estado; mostrar resultado informativo backend
* [ ] 11.9 Submit, errores y redirección/refresco tras creación

## 12. UI: Visit Detail

* [ ] 12.1 Crear header con visitante, documento, estado y dropdown Más acciones
* [ ] 12.2 Crear tabs Información, Documentos e Historial basado en [`mockups/visit_details.png.png`](mockups/visit_details.png.png)
* [ ] 12.3 Implementar detalle completo con datos, actores, vehículo/metadata, notas e historial funcional
* [ ] 12.4 Dejar Documentos como placeholder sin backend documental
* [ ] 12.5 Implementar detalle restringido con datos mínimos y acciones operativas
* [ ] 12.6 Renderizar timeline desde serializer de eventos
* [ ] 12.7 Mantener todas las acciones en dropdown y ocultar las ausentes en `permissions`

## 13. UI contextual para residentes/propietarios

* [x] 13.1 Añadir visitas en detalle de unidad/listado scoped
* [x] 13.2 Listar y crear visitas para unidades relacionadas
* [x] 13.3 Autorizar/cancelar según capabilities y estado
* [x] 13.4 Ocultar acciones no permitidas según backend
* [ ] 13.5 Revalidar que el flujo contextual comparte estado inicial backend, dropdowns e historial funcional

## 14. i18n, tests integrales y QA

* [x] 14.1 Añadir traducciones base de tipos, estados, acciones y labels en `es`, `en`, `pt`
* [ ] 14.2 Completar traducciones para superficies, dropdowns, metadata, timeline, errores y estados vacíos/loading
* [ ] 14.3 Tests integración `pending -> authorized -> checked_in -> checked_out`
* [ ] 14.4 Tests cancelación permitida/denegada e historial funcional
* [ ] 14.5 Tests conserjería: no crea/edita/autoriza/cancela; solo check-in/check-out válidos
* [ ] 14.6 Tests serializers y frontend afectado
* [ ] 14.7 QA manual conserjería: scope, tabs, dropdown, check-in y check-out
* [ ] 14.8 QA manual administración: listar, filtrar, crear, editar, autorizar, cancelar y detalle
* [ ] 14.9 QA cross-organization y cross-property
* [ ] 14.10 Ejecutar suite relevante, RuboCop y `npm run check`
* [ ] 14.11 Ejecutar `openspec validate visit-management --type change --strict`
* [ ] 14.12 Ejecutar `graphify update app` tras cambios de código
* [ ] 14.13 Preparar `CLOSURE.md` con decisiones y diferencias legacy
