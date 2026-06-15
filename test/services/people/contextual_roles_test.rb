# frozen_string_literal: true

require "test_helper"

module People
  class ContextualRolesTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      @person = Person.create!(
        organization: @organization,
        display_name: "Contextual Roles Person",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
      @unit = create_unit!(identifier: "CTX-ROLES-101")
    end

    teardown do
      ActsAsTenant.current_tenant = nil
    end

    test "returns owner when person has active ownership" do
      UnitOwnership.create!(
        organization: @organization,
        unit: @unit,
        person: @person,
        ownership_percentage: 50,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )

      roles = ContextualRoles.call(@person)

      assert_includes roles, ContextualRoles::OWNER
      refute_includes roles, ContextualRoles::RESIDENT
    end

    test "returns resident when person has active occupancy" do
      UnitOccupancy.create!(
        organization: @organization,
        unit: @unit,
        person: @person,
        occupancy_type: OccupancyTypes::TENANT,
        status: OccupancyStatuses::ACTIVE,
        starts_at: Time.current
      )

      roles = ContextualRoles.call(@person)

      assert_includes roles, ContextualRoles::RESIDENT
      refute_includes roles, ContextualRoles::OWNER
    end

    test "returns visitor when person has linked visitor profile" do
      VisitorProfile.create!(
        organization: @organization,
        person: @person,
        status: "active"
      )

      roles = ContextualRoles.call(@person)

      assert_includes roles, ContextualRoles::VISITOR
    end

    test "returns system_user when person is linked to user" do
      user = ActsAsTenant.without_tenant do
        User.create!(
          email: "system-user@example.test",
          password: "password1",
          password_confirmation: "password1",
          name: "System User",
          dni: SecureRandom.hex(4),
          language: Languages::ES,
          confirmed_at: Time.current
        )
      end
      @person.update!(user: user)

      roles = ContextualRoles.call(@person)

      assert_includes roles, ContextualRoles::SYSTEM_USER
    end

    test "returns multiple contextual roles simultaneously" do
      user = ActsAsTenant.without_tenant do
        User.create!(
          email: "multi-role@example.test",
          password: "password1",
          password_confirmation: "password1",
          name: "Multi Role",
          dni: SecureRandom.hex(4),
          language: Languages::ES,
          confirmed_at: Time.current
        )
      end
      @person.update!(user: user)

      UnitOwnership.create!(
        organization: @organization,
        unit: @unit,
        person: @person,
        ownership_percentage: 100,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )
      UnitOccupancy.create!(
        organization: @organization,
        unit: @unit,
        person: @person,
        occupancy_type: OccupancyTypes::OWNER_RESIDENT,
        status: OccupancyStatuses::ACTIVE,
        starts_at: Time.current
      )
      VisitorProfile.create!(
        organization: @organization,
        person: @person,
        status: "active"
      )

      roles = ContextualRoles.call(@person)

      assert_equal [
        ContextualRoles::OWNER,
        ContextualRoles::RESIDENT,
        ContextualRoles::VISITOR,
        ContextualRoles::SYSTEM_USER
      ], roles
    end

    test "returns empty roles when person has no contextual relationships" do
      roles = ContextualRoles.call(@person)

      assert_empty roles
    end

    test "does not include owner when ownership is inactive" do
      UnitOwnership.create!(
        organization: @organization,
        unit: @unit,
        person: @person,
        ownership_percentage: 100,
        starts_at: Date.current,
        status: "inactive"
      )

      roles = ContextualRoles.call(@person)

      refute_includes roles, ContextualRoles::OWNER
    end

    test "does not include resident when occupancy is inactive" do
      UnitOccupancy.create!(
        organization: @organization,
        unit: @unit,
        person: @person,
        occupancy_type: OccupancyTypes::TENANT,
        status: OccupancyStatuses::INACTIVE,
        starts_at: Time.current
      )

      roles = ContextualRoles.call(@person)

      refute_includes roles, ContextualRoles::RESIDENT
    end

    test "does not include staff roles before assignments exist" do
      UnitOwnership.create!(
        organization: @organization,
        unit: @unit,
        person: @person,
        ownership_percentage: 100,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )

      roles = ContextualRoles.call(@person)

      assert_not roles.intersect?(ContextualRoles::STAFF_ROLES)
    end

    test "person contextual_roles delegates to service" do
      UnitOwnership.create!(
        organization: @organization,
        unit: @unit,
        person: @person,
        ownership_percentage: 100,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )

      assert_equal ContextualRoles.call(@person), @person.contextual_roles
    end

    test "tenant_role is separate from contextual roles" do
      @person.set_tenant_role(AvailableRoles::TENANT_ADMIN)

      assert_equal AvailableRoles::TENANT_ADMIN, @person.tenant_role
      assert_empty @person.contextual_roles
    end

    private

    def create_unit!(identifier:)
      property = ResidentialProperty.create!(
        organization: @organization,
        name: "Contextual Roles Property",
        property_type: PropertyTypes::BUILDING,
        status: "active",
        country: "Chile",
        timezone: "America/Santiago"
      )
      Unit.create!(
        organization: @organization,
        residential_property: property,
        identifier: identifier,
        unit_type: UnitTypes::APARTMENT,
        status: UnitStatuses::AVAILABLE
      )
    end
  end
end
