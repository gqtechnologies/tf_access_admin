# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # def new
  #   render inertia: "auth/login", props: {
  #     submit_url: user_session_path,
  #   }
  # end

  # def create
  #   self.resource = warden.authenticate(auth_options)
  #   if resource
  #     set_flash_message!(:notice, :signed_in)
  #     sign_in(resource_name, resource)
  #     redirect_to after_sign_in_path_for(resource)
  #   else
  #     render inertia: "auth/login", props: {
  #       submit_url: user_session_path,
  #       errors: { base: [I18n.t("devise.failure.invalid")] },
  #     }, status: :unprocessable_entity
  #   end
  # end
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
