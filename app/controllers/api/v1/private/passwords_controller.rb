# frozen_string_literal: true

# PATCH /api/v1/private/me/password — the signed-in user changes their own
# password by proving the current one. Rejections are 422 with +field+ naming
# which input is wrong (+current_password+ or +password+), so the app can put
# the message next to it. The current session's token stays valid.
class Api::V1::Private::PasswordsController < Api::V1::Private::BaseController
  rate_limit to: 5, within: 15.minutes, only: :update,
             by: -> { current_user&.id || request.remote_ip },
             with: -> { render_too_many_requests }

  def update
    current_password = params[:current_password].to_s
    new_password = params[:password].to_s

    return reject(:current_password, "wrong_current") unless current_user.valid_password?(current_password)
    return reject(:password, "same_as_current") if new_password == current_password

    current_user.password = new_password
    current_user.password_confirmation = new_password

    if current_user.save
      head :no_content
    else
      # Drop the rejected digest so the in-memory user keeps matching the stored password.
      current_user.restore_attributes
      reject(:password, "weak")
    end
  end

  private

  def reject(field, key)
    render json: { error: I18n.t("api.password.#{key}"), field: field }, status: :unprocessable_entity
  end

  def render_too_many_requests
    response.set_header("Retry-After", 15.minutes.to_i.to_s)
    render json: { error: I18n.t("api.errors.too_many_requests") }, status: :too_many_requests
  end
end
