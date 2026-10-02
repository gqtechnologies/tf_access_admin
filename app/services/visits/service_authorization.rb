# frozen_string_literal: true

module Visits
  module ServiceAuthorization
    include Authorization::ActorContext

    private

    def authorize_visit_action!(record, query)
      with_actor_context do
        policy = VisitPolicy.new(@actor, record)
        raise Pundit::NotAuthorizedError unless policy.public_send(query)
      end
    end
  end
end
