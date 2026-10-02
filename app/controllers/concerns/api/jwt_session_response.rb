# frozen_string_literal: true

# Signs a user in for one API request and renders the session payload shared by
# every login route (password and Apple/Google). The JWT itself is minted by
# devise-jwt, which only does so on the routes registered in
# config/initializers/warden_jwt_api_routes.rb.
module Api::JwtSessionResponse
  extend ActiveSupport::Concern

  private

  def render_jwt_session(user, organization, extra = {})
    Current.organization = organization
    ActsAsTenant.with_tenant(organization) do
      sign_in(user, store: false)
    end

    token = request.env[Warden::JWTAuth::Hooks::PREPARED_TOKEN_ENV_KEY]
    unless token
      return render json: { error: I18n.t("api.errors.token_dispatch_failed") }, status: :internal_server_error
    end

    Current.reset

    render json: {
      data: {
        token: token,
        token_type: "Bearer",
        expires_in: Warden::JWTAuth.config.expiration_time,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          # Membership is guaranteed by the caller. Organizational roles win,
          # otherwise the user is a resident (owner/occupant) of the organization.
          role: Api::RoleResolver.call(user, organization)
        }
      }.merge(extra)
    }, status: :ok
  end
end
