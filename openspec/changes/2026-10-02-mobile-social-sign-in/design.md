## Context

El login por contraseña (`Api::V1::Auth::SessionsController`) resuelve la organización por subdominio y emite el JWT con devise-jwt, que solo lo hace en las rutas registradas en `warden_jwt_api_routes.rb`. `User` exige `name`, `dni` y una contraseña que cumpla la política. `Visits::NotifyVisitor` ya vincula a un usuario confirmado cuando un residente invita su correo.

## Goals / Non-Goals

**Goals:** que alguien pueda crearse una cuenta sin invitación y entrar con Apple o Google; no abrir una vía de toma de cuentas.

**Non-Goals:** registro con correo y contraseña; guardar el identificador del proveedor (`sub`) o desvincular proveedores; ingreso social en el admin web.

## Decisions

### D1 — La app obtiene el token, el backend lo verifica
El backend no hace el flujo OAuth: recibe el `id_token` y lo valida con `jwt` contra el JWKS del proveedor (cacheado una hora, con recarga cuando el `kid` no está, que es como se ve una rotación de claves). Sin gemas nuevas.

### D2 — La audiencia es la defensa central
Un token válido de Apple o Google emitido para *otra* app tiene firma correcta. Lo único que lo distingue es `aud`, por eso es obligatoria y sale de configuración: sin audiencia configurada el proveedor está deshabilitado (`503`) en vez de aceptar cualquiera.

### D3 — La cuenta se identifica por correo verificado
No se guarda `sub`: el correo que el proveedor declara verificado es la identidad, igual que abrir el enlace de un correo de invitación. Consecuencia aceptada: con "Ocultar mi correo" de Apple la cuenta queda con el correo de relevo, y un residente tendría que invitar ese correo.

### D4 — Datos faltantes como rechazo reintentable
`422 profile_required` en lugar de un endpoint de registro aparte: la app reenvía el mismo token con nombre y documento. Los tokens duran minutos, suficiente para llenar dos campos; si vence, la app vuelve a pedirlo.

### D5 — Contraseña generada
`User` exige contraseña. Se genera una aleatoria que nadie conoce; quien quiera una propia usa "¿Olvidaste tu contraseña?".

### D6 — Rol visitante y reutilización de la persona
Si ya existe en la organización una persona sin cuenta con ese correo (alguien la invitó antes), se vincula a ella y sus invitaciones aparecen de inmediato; si no, `Accounts::ProvisionTenantIdentity` con rol `visitor`.

## Risks / Trade-offs

- [Quien controle el correo en Google/Apple entra a la cuenta de ese correo] → Es el mismo nivel de confianza que la recuperación de contraseña por correo.
- [Cualquiera puede crearse una cuenta de visitante en cualquier organización] → Un visitante sin invitaciones no ve nada; límite de 10 solicitudes por IP cada 15 minutos.
- [Caída del JWKS del proveedor] → `401` genérico; el caché de una hora amortigua.
