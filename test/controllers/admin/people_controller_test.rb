# frozen_string_literal: true

require "test_helper"

class Admin::PeopleControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper

  setup do
    @organization = organizations(:one)
    @other_organization = organizations(:two)
    ActsAsTenant.current_tenant = @organization

    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "People Show Property",
      property_type: PropertyTypes::BUILDING,
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    @section = PropertySection.create!(
      organization: @organization,
      residential_property: @property,
      name: "Level 1",
      section_type: "floor"
    )
    @unit = Unit.create!(
      organization: @organization,
      residential_property: @property,
      property_section: @section,
      identifier: "PEO-101",
      unit_type: UnitTypes::APARTMENT,
      status: UnitStatuses::AVAILABLE
    )
    @person = Person.create!(
      organization: @organization,
      display_name: "People Show Person",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE,
      document_number: "12.345.678-9"
    )
    @ownership = UnitOwnership.create!(
      organization: @organization,
      unit: @unit,
      person: @person,
      ownership_percentage: 100,
      starts_at: Date.current,
      status: UnitOwnership::STATUS_ACTIVE
    )
    @occupancy = UnitOccupancy.create!(
      organization: @organization,
      unit: @unit,
      person: @person,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: Time.current,
      status: OccupancyStatuses::ACTIVE
    )

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "people-show-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
    @non_admin = create_user_for_organization(
      organization: @organization,
      email: "people-show-client@example.test",
      role: AvailableRoles::CLIENT
    )

    @other_org_person = ActsAsTenant.with_tenant(@other_organization) do
      Person.create!(
        organization: @other_organization,
        display_name: "Other Org Person",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
    end
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "show route renders unified profile props" do
    sign_in_as(@tenant_admin)

    inertia_get admin_person_path(@person)

    assert_response :success
    props = inertia_props

    assert_equal @person.id, props["person"]["id"]
    assert_includes props["contextual_roles"], People::ContextualRoles::OWNER
    assert_includes props["contextual_roles"], People::ContextualRoles::RESIDENT
    assert_equal 1, props["summary"]["active_ownerships_count"]
    assert_equal 1, props["summary"]["active_occupancies_count"]
    assert_equal 0, props["summary"]["visits_count"]
    assert_equal 0, props["summary"]["staff_assignments_count"]
    assert_equal [], props["staff_assignments"]
    assert_equal [], props["visits"]
    assert props["permissions"]["edit"]
    assert props["permissions"]["update"]
    assert props["permissions"]["destroy"]
    assert_equal 1, props["ownerships"].size
    assert_equal "People Show Property", props["ownerships"].first["residential_property_name"]
    assert_equal "Level 1", props["ownerships"].first["property_section_name"]
    assert_equal "PEO-101", props["ownerships"].first["unit_identifier"]
    assert_equal 1, props["occupancies"].size
    assert props["ownerships_pagination"]["total_count"].present?
    assert props["occupancies_pagination"]["total_count"].present?
    assert props["change_history"].is_a?(Array)
  end

  test "show denies access for non admin user" do
    sign_in_as(@non_admin)

    inertia_get admin_person_path(@person)

    assert_response :redirect
  end

  test "show does not expose person from another organization" do
    sign_in_as(@tenant_admin)

    inertia_get admin_person_path(@other_org_person)

    assert_redirected_to admin_people_url(host: "#{@organization.subdomain}.example.com")
  end

  test "show serializes multiple ownership rows with preloaded property context" do
    2.times do |index|
      unit = Unit.create!(
        organization: @organization,
        residential_property: @property,
        property_section: @section,
        identifier: "PEO-10#{index + 2}",
        unit_type: UnitTypes::APARTMENT,
        status: UnitStatuses::AVAILABLE
      )
      UnitOwnership.create!(
        organization: @organization,
        unit: unit,
        person: @person,
        ownership_percentage: 10,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )
    end

    sign_in_as(@tenant_admin)
    inertia_get admin_person_path(@person)

    assert_response :success
    assert_equal 3, inertia_props["ownerships"].size
    assert inertia_props["ownerships"].all? { |row| row["residential_property_name"].present? }
    assert inertia_props["ownerships"].all? { |row| row["unit_identifier"].present? }
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "password1" } }
  end
end
