# frozen_string_literal: true

module Accounts
  # Accepts an account invitation by its single-use token, verifying the token
  # digest, expiration, and pending state before granting anything (possession
  # of the link alone is insufficient — the holder must be the resolved account).
  #
  # This slice supports incorporation of an EXISTING account (Flow C): it links
  # the account to the person and finalizes onboarding. Creating a NEW account on
  # accept is deferred to the controllers slice, because it depends on removing
  # +User#provision_tenant_identity+ (tasks §18/§21) to avoid a duplicate Person.
  class AcceptInvitation
    class InvalidToken < StandardError; end
    class Expired < StandardError; end
    class AccountRequired < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(token:, organization:)
      @token = token
      @organization = organization
    end

    def call
      request = find_pending_request!
      raise Expired if request.expires_at.past?
      raise AccountRequired, "new-account creation on accept is deferred (§18/§21)" if request.user.blank?

      OnboardingRequest.transaction do
        Accounts::LinkUserToPerson.call(person: request.person, user: request.user)
        consume_token(request)
        Memberships::AcceptOnboarding.call(onboarding_request: request)
      end
    end

    private

    def find_pending_request!
      digest = Accounts::InvitePerson.token_digest(@token)
      request = OnboardingRequest.where(organization_id: @organization.id, token_digest: digest).first
      raise InvalidToken if request.blank? || !request.pending?

      request
    end

    def consume_token(request)
      request.update!(token_digest: nil)
    end
  end
end
