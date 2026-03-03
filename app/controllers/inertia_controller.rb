# frozen_string_literal: true

class InertiaController < ApplicationController
  # Share data with all Inertia responses
  # see https://inertia-rails.dev/guide/shared-data
  #   inertia_share user: -> { Current.user&.as_json(only: [:id, :name, :email]) }

  # inertia_share auth: -> {
  #   if user_signed_in?
  #     { user: current_user.as_json(only: [:id, :email]) }
  #   else
  #     {}
  #   end
  # }
end
