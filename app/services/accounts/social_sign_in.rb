# frozen_string_literal: true

module Accounts
  # Resolves the account for a verified Apple/Google identity within an
  # organization, creating it when the email is new.
  #
  # - Email already belongs to a member of the organization → that account.
  # - Email has an account elsewhere (or a Person here without an account) →
  #   it joins this organization as a visitor.
  # - Email is unknown → a new, confirmed visitor account. The provider proves
  #   the email; name and document must come from the user (ProfileRequired
  #   lists what is missing so the app can ask and retry).
  #
  # A self-registered visitor has no unit: they only become useful once a
  # resident invites that email (Visits::NotifyVisitor links confirmed users).
  class SocialSignIn
    class EmailRequired < StandardError; end
    class Deactivated < StandardError; end

    class ProfileRequired < StandardError
      attr_reader :missing

      def initialize(missing)
        @missing = missing
        super("profile data required: #{missing.join(', ')}")
      end
    end

    Result = Struct.new(:user, :created, keyword_init: true)

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(organization:, claims:, name: nil, dni: nil, language: nil)
      @organization = organization
      @claims = claims
      @name = name.to_s.strip.presence || claims.name
      @dni = dni.to_s.strip.presence
      @language = language
    end

    def call
      raise EmailRequired if @claims.email.blank? || !@claims.email_verified

      user = ActsAsTenant.without_tenant { User.find_by(email: @claims.email) }
      created = user.nil?

      ActsAsTenant.with_tenant(@organization) do
        ActiveRecord::Base.transaction do
          user ||= create_user!
          raise Deactivated if user.deactivated_at.present?

          # The provider vouches for the email, same as opening an emailed link.
          user.update!(confirmed_at: Time.current) if user.confirmed_at.blank?
          join_organization(user) unless user.super_admin? || user.member_of_tenant?(@organization)
        end
      end

      Result.new(user: user, created: created)
    end

    private

    def create_user!
      missing = []
      missing << "name" if @name.blank?
      missing << "dni" if @dni.blank?
      raise ProfileRequired, missing if missing.any?

      password = generated_password
      user = User.new(
        email: @claims.email,
        password: password,
        password_confirmation: password,
        name: @name,
        dni: @dni,
        language: Languages::ALL.include?(@language.to_s) ? @language.to_s : I18n.default_locale.to_s
      )
      user.skip_confirmation!
      user.save!
      user
    end

    # Never shown to anyone: the account signs in through the provider, and
    # "forgot password" is the way to get a password of one's own.
    def generated_password
      "Aa1@#{SecureRandom.hex(24)}"
    end

    # Reuses the Person a resident may already have created by inviting this
    # email, so those invitations show up right away.
    def join_organization(user)
      person = unlinked_person_for(user.email)

      if person
        Accounts::LinkUserToPerson.call(person: person, user: user)
        membership = person.organization_membership ||
          OrganizationMembership.create!(organization: @organization, person: person)
        membership.accept! if membership.may_accept?
        person.add_role(AvailableRoles::VISITOR, @organization) unless person.has_role?(AvailableRoles::VISITOR, @organization)
      else
        Accounts::ProvisionTenantIdentity.call(user: user, organization: @organization, role: AvailableRoles::VISITOR)
      end
    end

    def unlinked_person_for(email)
      Person.where(organization_id: @organization.id, user_id: nil, email_digest: Person.email_digest(email))
            .order(:created_at)
            .first
    end
  end
end
