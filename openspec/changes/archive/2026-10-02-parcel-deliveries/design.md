## Context

`parcel_deliveries` y `parcel_delivery_status_histories` ya existen (estado string, `received_at`, `withdrawn_at`, `received_by_person`, `withdrawn_by_person`, `notified_at`). `UnitOccupancy#can_withdraw_parcels` existe pero no se expone en el admin. Los push salen por `Notification` + `DeliverPushNotificationJob`, con un payload por `notification_type`; `NotificationTypes::PARCEL` ya está en el catálogo. La conserjería móvil fija cada request a una propiedad con `Api::ConciergePropertyContext`.

Este change se apila sobre `2026-10-02-mobile-unit-residents`, que agrega las consultas de relaciones vigentes por unidad.

## Goals / Non-Goals

**Goals:** dominio y API completos y probados, listos para la app y la web.

**Non-Goals:** pantallas (changes siguientes); fotos o firma del retiro (`parcel_requires_signature`); recordatorios; `authorized_residents`; turnos de staff; retiro por terceros sin cuenta.

## Decisions

### D1 — Dos estados, sin AASM
`received` y `withdrawn` en `ParcelStatuses`. Una sola transición no justifica una máquina de estados; `Parcels::Withdraw` la protege con `with_lock` y revalida el estado dentro del bloqueo.

### D2 — Capacidad propia `manage_parcels`
No se reutiliza `register_visit_entry`: son permisos distintos y la matriz de roles del admin debe poder mostrarlos por separado. Se suma a `CONCIERGE` y `PROPERTY_ADMIN`, a `ALL` (org admins) y a un módulo `parcels` en `OperationalRoles::Presentation`.

### D3 — `ParcelDeliveryPolicy` + autorización dentro de los servicios
Igual que visitas: los servicios autorizan con la política bajo el contexto del actor (`Visits::ServiceAuthorization#with_actor_context`, extraído a `Authorization::ActorContext` para no depender del namespace de visitas). El `Scope` devuelve todo para org-wide y, si no, las propiedades con `manage_parcels`.

### D4 — Quién puede retirar: `Parcels::EligibleWithdrawers`
Ocupaciones vigentes de la unidad con `can_withdraw_parcels`. Los propietarios sin ocupación no tienen esa bandera y por lo tanto no retiran: decisión del usuario ("solo con permiso de retiro"). Consecuencia: mientras el admin no active la bandera, nadie puede retirar; el interruptor en el formulario de ocupantes va en el change de la web.

### D5 — Aviso a toda la unidad, fuera de la transacción
`Parcels::NotifyResidents` crea una `Notification` por persona distinta (ocupantes + propietarios vigentes) después de confirmar el registro, y captura cualquier error. `DeliverPushNotificationJob` ya omite a quien no tiene dispositivo.

### D6 — La API del residente no pagina
Pendientes + retiradas de 30 días, tope de 50. Una unidad no acumula más que eso y la app lo muestra en un sheet.

### D7 — `property_id` obligatorio en conserjería
Mismo contrato que `concierge/visits`: `403` si falta o no se opera. Las propiedades operadas para encomiendas se calculan con `manage_parcels` (para un conserje coinciden con las de visitas, así que la app reutiliza `GET /concierge/properties`).

## Risks / Trade-offs

- [Nadie tiene `can_withdraw_parcels` hoy] → Sin el change de la web no hay retiros posibles; el detalle devuelve `eligible_withdrawers: []` y la app/web lo explican.
- [Agregar una capacidad cambia la matriz de roles] → Tests de resolver/roles se corren junto con los nuevos.
