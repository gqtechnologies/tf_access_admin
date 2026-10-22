# frozen_string_literal: true

require "test_helper"

class Accounts::DeleteAccountTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include ParcelTestHelper

  setup do
    setup_parcel_world("DEL")
    @user = @picker
    @person = person_of(@user)
    @person.document_number = "12.345.678-5"
    @person.contact_phone = "+56 912345678"
    @person.birthdate = Date.new(1990, 5, 20)
    @person.save!
    @occupancy = @person.unit_occupancies.first
    @parcel = create_parcel(@unit, status: ParcelStatuses::WITHDRAWN, received_at: 2.hours.ago, withdrawn_at: 1.hour.ago, withdrawn_by_person: @person)
    @profile = VisitorProfile.create!(
      organization: @organization, person: @person, status: "active",
      external_name: "Ana Picker", company_name: "Picker SpA", security_notes: "Viene en auto rojo"
    )
    DeviceToken.create!(user: @user, token: "ExponentPushToken[delete-me]", platform: "ios")
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "anonymizes the user, frees the email and blocks the old password" do
    old_email = @user.email

    Accounts::DeleteAccount.call(user: @user)
    @user.reload

    assert_equal "Persona eliminada", @user.name
    assert_equal "deleted-#{@user.id}@deleted.invalid", @user.email
    assert_equal "-", @user.dni
    assert_nil @user.phone_number
    assert_nil @user.date_of_birth
    assert @user.deactivated_at.present?
    assert_not @user.valid_password?("Password1@")
    assert_nil User.find_by(email: old_email)
    assert_nil DeviceToken.find_by(user_id: @user.id)
  end

  test "anonymizes the person and revokes the membership but keeps history and units" do
    Accounts::DeleteAccount.call(user: @user)
    # A fresh read: Person keeps the document and phone it was given in memory.
    @person = Person.find(@person.id)

    assert_equal "Persona eliminada", @person.display_name
    assert_nil @person.first_name
    assert_nil @person.birthdate
    assert_nil @person.document_number_digest
    assert_nil @person.document_number
    assert_nil @person.contact_phone
    assert_equal [ "anonymized_at" ], @person.metadata.keys
    assert_equal PersonStatuses::INACTIVE, @person.status
    assert_nil @person.user_id
    assert_nil @person.contact_email
    assert @person.organization_membership.revoked?

    assert UnitOccupancy.exists?(@occupancy.id)
    assert_equal @person.id, @parcel.reload.withdrawn_by_person_id
  end

  test "clears visitor profiles and redacts names from the people audit trail" do
    Accounts::DeleteAccount.call(user: @user)

    @profile.reload
    assert_nil @profile.external_name
    assert_nil @profile.company_name
    assert_nil @profile.security_notes

    audits = Audited::Audit.where(auditable_type: "Person", auditable_id: @person.id)
    assert audits.any?
    assert audits.none? { |audit| audit.audited_changes.to_s.include?("Ana Picker") }
  end

  test "super admins can't delete their own account" do
    admin = create_user_for_organization(
      organization: @organization, email: "del-super@example.test", role: AvailableRoles::SUPER_ADMIN
    )

    assert_raises(Accounts::DeleteAccount::NotAllowed) { Accounts::DeleteAccount.call(user: admin) }
    assert_nil admin.reload.deactivated_at
  end
end
