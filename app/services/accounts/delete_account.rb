# frozen_string_literal: true

module Accounts
  # Deletes a user's account at their own request (the App Store and Google
  # Play require it in the app) by anonymizing it instead of destroying rows:
  # visits, parcels, reservations and incidents keep their history, but nothing
  # left in them identifies the person.
  #
  # - The User keeps its id (visits and audits point at it) but loses its name,
  #   email, document, phone, birthdate, avatar, push token and password, and is
  #   deactivated. The email is freed, so the person can sign up again later.
  # - Every Person linked to it, in every organization, becomes "Persona
  #   eliminada" with no document, contact data or birthdate, is unlinked from
  #   the User (its contact email would otherwise fall back to the placeholder)
  #   and has its membership revoked. Unit ownerships and occupancies stay
  #   (anonymous) until the administration ends them: an ownership is a legal
  #   record it must decide on.
  # - Visit participants, visitor profiles and the people audit trail drop the
  #   names and documents they copied.
  #
  # Columns are written with +update_columns+: Person's callbacks would derive
  # the email back from the User, +audited+ would store the old values in a new
  # audit, and Devise would mail a reconfirmation to the placeholder address.
  #
  # Super admins can't delete themselves here; that would lock the platform out.
  class DeleteAccount
    class NotAllowed < StandardError; end

    REDACTED_AUDIT_KEYS = %w[display_name first_name last_name].freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def self.anonymous_name
      I18n.t("accounts.deletion.anonymous_name", locale: :es)
    end

    def initialize(user:)
      @user = user
      @now = Time.current
    end

    def call
      raise NotAllowed, "super admins can't delete their own account" if @user.super_admin?

      people = ActsAsTenant.without_tenant { @user.people.includes(:organization, :organization_membership).to_a }

      ActiveRecord::Base.transaction do
        people.each { |person| ActsAsTenant.with_tenant(person.organization) { anonymize_person!(person) } }
        anonymize_user!
      end

      @user.avatar.purge_later if @user.avatar.attached?
      @user
    end

    private

    def anonymize_person!(person)
      person.update_columns(
        display_name: self.class.anonymous_name,
        first_name: nil,
        last_name: nil,
        birthdate: nil,
        document_type: nil,
        document_number_ciphertext: nil,
        document_number_digest: nil,
        email_ciphertext: nil,
        email_digest: nil,
        phone_ciphertext: nil,
        metadata: { "anonymized_at" => @now.iso8601 },
        status: PersonStatuses::INACTIVE,
        user_id: nil,
        updated_at: @now
      )

      membership = person.organization_membership
      membership.revoke! if membership&.may_revoke?

      person.visitor_profiles.update_all(
        external_name: nil,
        company_name: nil,
        document_type: nil,
        document_number_ciphertext: nil,
        document_number_digest: nil,
        email_ciphertext: nil,
        phone_ciphertext: nil,
        security_notes: nil,
        metadata: {},
        updated_at: @now
      )

      VisitParticipant.where(person_id: person.id).update_all(
        name_snapshot: self.class.anonymous_name,
        document_snapshot_digest: nil,
        updated_at: @now
      )

      redact_audits!(person)
    end

    def redact_audits!(person)
      Audited::Audit.where(auditable_type: "Person", auditable_id: person.id).find_each do |audit|
        changes = audit.audited_changes
        next unless changes.is_a?(Hash) && changes.keys.intersect?(REDACTED_AUDIT_KEYS)

        REDACTED_AUDIT_KEYS.each do |key|
          next unless changes.key?(key)

          changes[key] = changes[key].is_a?(Array) ? changes[key].map { nil } : nil
        end
        audit.update_columns(audited_changes: changes)
      end
    end

    def anonymize_user!
      @user.update_columns(
        name: self.class.anonymous_name,
        email: "deleted-#{@user.id}@deleted.invalid",
        unconfirmed_email: nil,
        dni: "-",
        phone_country_code: nil,
        phone_number: nil,
        date_of_birth: nil,
        gender: nil,
        metadata: { "deleted_by_user_at" => @now.iso8601 },
        encrypted_password: Devise::Encryptor.digest(User, "#{SecureRandom.base58(32)}aA1$"),
        confirmation_token: nil,
        reset_password_token: nil,
        reset_password_sent_at: nil,
        remember_created_at: nil,
        deactivated_at: @now,
        updated_at: @now
      )
      @user.device_token&.destroy!
    end
  end
end
