# frozen_string_literal: true

module Devise
  # When authentication fails (no session, invalid session, or deleted user),
  # sign out the scope so any stale session/cookie is cleared, then redirect
  # to login. This ensures the user always lands on the sign-in page in a
  # clean state.
  class CustomFailureApp < Devise::FailureApp
    def redirect
      clear_stale_session!
      super
    end

    private

    def clear_stale_session!
      return unless warden.authenticated?(scope: scope)

      warden.logout(scope)
    end
  end
end
