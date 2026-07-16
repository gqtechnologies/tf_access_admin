# frozen_string_literal: true

require "digest"

module Accounts
  # Issues an account invitation for a person, resolving identity first:
  #
  # - conflict          → records a conflict request, no token, no changes
  # - matched_person    → reuses the existing +Person+
  # - matched_account   → creates the org +Person+ and references the existing
  #                       account for later incorporation (Flow C)
  # - none              → creates a new +Person+ (Flow A/B)
  #
  # Returns a +Result+ with the pending +OnboardingRequest+ and the raw,
  # single-use token (only its SHA-256 digest is persisted). Email delivery is
  # plumbing left to a mailer (this service returns the token to send). Membership
  # activation is a separate concern (+Memberships::RequestOnboarding+).
  class InvitePerson
    DEFAULT_EXPIRES_IN = 14.days

    Result = Data.define(:onboarding_request, :token, :person) do
      def conflict? = onboarding_request.conflict?
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def self.token_digest(raw_token)
      Digest::SHA256.hexdigest(raw_token.to_s)
    end

    def initialize(organization:, email:, requested_relationship: OnboardingRequest::RELATIONSHIP_MEMBERSHIP,
                   requested_by_person: nil, first_name: nil, last_name: nil,
                   document_number: nil, phone: nil, requested_roles: [],
                   expires_in: DEFAULT_EXPIRES_IN)
      @organization = organization
      @email = email
      @requested_relationship = requested_relationship
      @requested_by_person = requested_by_person
      @first_name = first_name
      @last_name = last_name
      @document_number = document_number
      @phone = phone
      @requested_roles = requested_roles
      @expires_in = expires_in
    end

    def call
      match = resolve_identity

      OnboardingRequest.transaction do
        return conflict_result(match.conflict_reason) if match.conflict?

        person = resolve_or_create_person(match)
        raw_token = SecureRandom.urlsafe_base64(32)
        request = create_invitation(person, match.user, raw_token)
        Result.new(onboarding_request: request, token: raw_token, person: person)
      end
    end

    private

    def resolve_identity
      People::ResolveIdentityMatch.call(
        organization: @organization,
        email: @email,
        document_number: @document_number
      )
    end

    def resolve_or_create_person(match)
      return match.person if match.person.present?

      People::Create.call(
        organization: @organization,
        first_name: @first_name,
        last_name: @last_name,
        email: @email,
        phone: @phone,
        document_number: @document_number
      )
    end

    def create_invitation(person, user, raw_token)
      OnboardingRequest.create!(
        organization: @organization,
        person: person,
        user: user,
        requested_relationship: @requested_relationship,
        requested_roles: @requested_roles,
        requested_by_person: @requested_by_person,
        status: OnboardingRequest::STATUS_PENDING,
        token_digest: self.class.token_digest(raw_token),
        expires_at: @expires_in.from_now
      )
    end

    def conflict_result(reason)
      request = OnboardingRequest.create!(
        organization: @organization,
        requested_relationship: @requested_relationship,
        requested_roles: @requested_roles,
        requested_by_person: @requested_by_person,
        status: OnboardingRequest::STATUS_CONFLICT,
        conflict_reason: reason,
        expires_at: @expires_in.from_now
      )
      Result.new(onboarding_request: request, token: nil, person: nil)
    end
  end
end
