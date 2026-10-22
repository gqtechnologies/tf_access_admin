# Tasks

## 1. Dominio

- [x] 1.1 `Accounts::DeleteAccount`: anonimiza `User`, sus `Person` (membresía revocada, desvinculadas), `VisitorProfile`, `VisitParticipant` y la auditoría de `Person`; verificado con `test/services/accounts/delete_account_test.rb`.

## 2. API

- [x] 2.1 `DELETE /api/v1/private/me` (`ProfilesController#destroy`, `403` para super admin) y `401` para usuarios desactivados en `Api::V1::Private::BaseController`; verificado con `test/controllers/api/v1/private/profiles_controller_test.rb`.

## 3. Validación

- [x] 3.1 Tests de `test/controllers/api`, `test/services/accounts` y `test/integration` en verde; `rubocop` sin novedades.
- [ ] 3.2 Prueba manual: eliminar una cuenta desde la app y ver la ficha "Persona eliminada" en la web. (Usuario)
- [x] 3.3 Revocar el token de Sign in with Apple al eliminar la cuenta: `SocialAuth::AppleTokenRevocation` con el `appleAuthorizationCode` que manda la app; `signInWithApple` en `/me`; verificado con `test/services/social_auth/apple_token_revocation_test.rb` y los tests de `DELETE /me`.
- [ ] 3.4 Cargar `APPLE_SIGN_IN_TEAM_ID`, `APPLE_SIGN_IN_KEY_ID` y `APPLE_SIGN_IN_PRIVATE_KEY` en Dokploy; hasta entonces la revocación se omite y queda en el log. (Usuario)
