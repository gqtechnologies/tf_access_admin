# frozen_string_literal: true

class AdminController < InertiaController
    inertia_share auth: -> {
      if user_signed_in?
        { user: current_user.as_json(only: [:id, :email]) }
      else
        {}
      end
    }
end