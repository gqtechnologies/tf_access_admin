# frozen_string_literal: true

module Parcels
  module ServiceAuthorization
    include Authorization::ActorContext

    private

    def authorize_parcel_action!(record, query)
      with_actor_context do
        policy = ParcelDeliveryPolicy.new(@actor, record)
        raise Pundit::NotAuthorizedError unless policy.public_send(query)
      end
    end

    def actor_person
      @actor.person_for(ActsAsTenant.current_tenant)
    end
  end
end
