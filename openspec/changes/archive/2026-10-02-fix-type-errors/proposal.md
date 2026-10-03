## Why

`npm run check` (vue-tsc) fallaba siempre con dos errores ajenos a cualquier cambio reciente, así que un error nuevo pasaba desapercibido entre ellos.

## What Changes

- `MultiFileGridUpload.vue` importaba `ProductPhotoRef` de `@/types/product`, un archivo que no existe (resto de la plantilla). Se define en el componente el tipo que realmente usa: `signed_id` y `url`.
- `useUnitAddOwnerDrawer.ts`: `indexOf` sobre una unión de tuplas solo aceptaba su miembro común; se amplía al tipo de paso.
- Sin cambios de comportamiento.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- `app/javascript/components/custom/inputs/MultiFileGridUpload.vue`, `app/javascript/lib/composables/unit/useUnitAddOwnerDrawer.ts`.
