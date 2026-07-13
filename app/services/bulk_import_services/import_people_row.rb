# frozen_string_literal: true

module BulkImportServices
  # Creates an active natural Person and an accepted OrganizationMembership
  # per validated row (add-bulk-user-import). No User/login account, role, or
  # unit assignment is created here — see proposal.md Non-Goals.
  class ImportPeopleRow
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(row:, bulk_import:)
      @row = row
      @bulk_import = bulk_import
      @payload = row.normalized_payload.deep_stringify_keys
    end

    def call
      return skip_duplicate! if duplicate_row?
      return skip_pending! if @row.import_status == BulkImportRow::IMPORT_STATUSES[:skipped]

      person = create_person!
      ensure_membership!(person)
      mark_imported!(person)
      :imported
    rescue ActiveRecord::RecordInvalid => e
      mark_failed!(e.record.errors.full_messages.join(", "))
      :failed
    rescue StandardError => e
      mark_failed!(e.message)
      :failed
    end

    private

    def duplicate_row?
      @row.validation_status == BulkImportRow::VALIDATION_STATUSES[:duplicate]
    end

    def skip_duplicate!
      mark_skipped!(I18n.t("frontend.admin.bulk_imports.import.logs.duplicate_skipped"))
      :skipped
    end

    def skip_pending!
      mark_skipped!(I18n.t("frontend.admin.bulk_imports.import.logs.skipped"))
      :skipped
    end

    def create_person!
      person = Person.new(
        organization: @bulk_import.organization,
        first_name: @payload["first_name"],
        last_name: @payload["last_name"],
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE,
        birthdate: parsed_birthdate
      )
      person.document_number = @payload["document_number"]
      person.contact_email = @payload["email"]
      person.contact_phone = @payload["phone"]
      person.save!
      person
    end

    def ensure_membership!(person)
      membership = OrganizationMembership.create!(organization: person.organization, person: person)
      membership.accept! if membership.may_accept?
      membership
    end

    def parsed_birthdate
      value = @payload["birthdate"]
      return nil if value.blank?

      Date.iso8601(value)
    rescue ArgumentError
      nil
    end

    def mark_imported!(person)
      @row.update!(
        import_status: BulkImportRow::IMPORT_STATUSES[:imported],
        imported_at: Time.current,
        target_record: person,
        operation: "create",
        failure_message: nil
      )
    end

    def mark_skipped!(message)
      @row.update!(
        import_status: BulkImportRow::IMPORT_STATUSES[:skipped],
        skipped_at: Time.current,
        failure_message: message
      )
    end

    def mark_failed!(message)
      @row.update!(
        import_status: BulkImportRow::IMPORT_STATUSES[:failed],
        failed_at: Time.current,
        failure_message: message
      )
    end
  end
end
