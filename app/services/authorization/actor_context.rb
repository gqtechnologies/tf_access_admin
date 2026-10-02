# frozen_string_literal: true

module Authorization
  # Runs a block with Current pointing at a service's +@actor+, so a policy
  # built inside it resolves capabilities for that actor (and never reuses a
  # grant profile cached for someone else). Restores the previous Current after.
  module ActorContext
    private

    def with_actor_context
      previous_user = Current.user
      previous_person = Current.person
      previous_profile = Current.authorization_grant_profile
      organization = ActsAsTenant.current_tenant

      Current.user = @actor
      Current.person = @actor.person_for(organization) if organization
      Current.authorization_grant_profile = nil

      yield
    ensure
      Current.user = previous_user
      Current.person = previous_person
      Current.authorization_grant_profile = previous_profile
    end
  end
end
