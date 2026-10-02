## Context

`Concierge::VisitsController` es el patrón de la conserjería web: página Inertia con tabla, pestañas con contadores, búsqueda por `q[query]`, drawers laterales que hacen `router.post` y vuelven por redirect (los rechazos viajan como `errors` de Inertia). El permiso `can_authorize_visits` ya recorre todo el flujo de ocupantes (controlador → `UnitOccupancies::Mutation`/`Update` → serializer → formularios y tabla).

## Goals / Non-Goals

**Goals:** que el permiso de retiro se pueda administrar y que la web cubra el mismo flujo que la app.

**Non-Goals:** detalle por encomienda en una página propia; edición o anulación de una encomienda; reportes.

## Decisions

### D1 — Un solo `index` con drawers, sin página `show`
La encomienda tiene pocos campos y todos caben en la fila. Los residentes habilitados viajan en cada fila pendiente (memoizados por unidad), así el drawer de retiro no necesita otra petición.

### D2 — Propiedad activa: `property_id` válido o la primera
A diferencia de visitas (que deja `nil` con varias propiedades), acá siempre hay una propiedad activa y un selector: registrar una llegada necesita la lista de unidades de una propiedad concreta. Un `property_id` no operado se ignora en vez de dar error.

### D3 — Unidades de la propiedad como prop
Se envían `id` y nombre de las unidades de la propiedad activa (tope 2000) para un select nativo. Un buscador remoto sería más liviano, pero la página es Inertia y no hay endpoint JSON de unidades en la web.

### D4 — El permiso de retiro replica `can_authorize_visits`
Mismo recorrido y mismos componentes, con un segundo checkbox. No se crea un formulario aparte.

## Risks / Trade-offs

- [Propiedades con miles de unidades vuelven pesado el select] → Tope de 2000 y decisión revisable (buscador remoto).
- [Dos errores de tipos previos en `npm run check`, ajenos a este change] → No se tocan.
