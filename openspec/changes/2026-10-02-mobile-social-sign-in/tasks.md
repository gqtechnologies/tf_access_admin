# Tasks

## 1. Verificación de tokens (D1, D2)

- [x] 1.1 `SocialAuth::Jwks` y `SocialAuth::TokenVerifier`; verificado con `test/services/social_auth/token_verifier_test.rb` (tokens RS256 firmados en el test).

## 2. Cuenta y sesión (D3–D6)

- [x] 2.1 `Accounts::SocialSignIn`.
- [x] 2.2 `Api::JwtSessionResponse` extraído del login; verificado con los tests existentes de `sessions_controller`.
- [x] 2.3 Ruta, despacho de JWT y `Api::V1::Auth::SocialSessionsController`; verificado con su test de controlador (12 tests).

## 3. Validación

- [x] 3.1 `rubocop` sobre los archivos tocados y `brakeman` sin advertencias.
- [ ] 3.2 Configurar `GOOGLE_SIGN_IN_CLIENT_IDS` en producción y probar con tokens reales de Apple y Google. (Usuario)
