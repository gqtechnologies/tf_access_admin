# frozen_string_literal: true

require "test_helper"

# Canonical section mutation channel and structure props
# (improve-property-sections §9.21 controllers delegate to services, §9.22 minimal
# backend-driven props).
class Admin::ResidentialProperties::PropertySectionsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @property = create_property(@organization, "Sections Controller Property")
    @tower = @property.property_sections.create!(
      organization: @organization,
      name: "Torre A",
      section_type: SectionTypes::TOWER
    )

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "sections-ctrl-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
    @client = create_user_for_organization(
      organization: @organization,
      email: "sections-ctrl-client@example.test",
      role: AvailableRoles::CLIENT
    )

    @structure_path = admin_residential_property_structure_path(@property)
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  # 9.21
  test "create delegates to the service and derives organization from the property" do
    sign_in_as(@tenant_admin)

    assert_difference -> { @property.property_sections.count }, 1 do
      post admin_residential_property_property_sections_path(@property), params: {
        property_section: { name: "Torre B", section_type: SectionTypes::TOWER }
      }
    end

    section = @property.property_sections.order(:created_at).last
    assert_equal @organization.id, section.organization_id
    assert_equal SectionStatuses::ACTIVE, section.status
    assert_redirected_to @structure_path
  end

  # 9.21 / §7.8
  test "create ignores a client-supplied organization_id" do
    sign_in_as(@tenant_admin)

    post admin_residential_property_property_sections_path(@property), params: {
      property_section: {
        name: "Torre C",
        section_type: SectionTypes::TOWER,
        organization_id: organizations(:two).id
      }
    }

    assert_equal @organization.id, @property.property_sections.find_by(name: "Torre C").organization_id
  end

  # §3: a non-existent parent_id must not create an accidental root section.
  test "create with a non-existent parent_id does not create a root section" do
    sign_in_as(@tenant_admin)

    assert_no_difference -> { @property.property_sections.count } do
      post admin_residential_property_property_sections_path(@property), params: {
        property_section: {
          name: "Orphan Section",
          section_type: SectionTypes::FLOOR,
          parent_id: SecureRandom.uuid
        }
      }
    end

    assert_redirected_to @structure_path
  end

  # §3: a parent from another property must not create an accidental root section.
  test "create with a cross-property parent_id does not create a root section" do
    sign_in_as(@tenant_admin)
    other_property = create_property(@organization, "Cross Parent Property")
    foreign_parent = other_property.property_sections.create!(
      organization: @organization,
      name: "Torre Externa",
      section_type: SectionTypes::TOWER
    )

    assert_no_difference -> { @property.property_sections.count } do
      post admin_residential_property_property_sections_path(@property), params: {
        property_section: {
          name: "Cross Parent Section",
          section_type: SectionTypes::FLOOR,
          parent_id: foreign_parent.id
        }
      }
    end
  end

  # 9.21
  test "update delegates descriptive changes to the service" do
    sign_in_as(@tenant_admin)

    patch admin_residential_property_property_section_path(@property, @tower), params: {
      property_section: { name: "Torre Renamed" }
    }

    assert_equal "Torre Renamed", @tower.reload.name
    assert_redirected_to @structure_path
  end

  # 9.21
  test "move delegates parent changes to the service" do
    sign_in_as(@tenant_admin)
    tower_b = @property.property_sections.create!(
      organization: @organization,
      name: "Torre B",
      section_type: SectionTypes::TOWER
    )
    floor = @property.property_sections.create!(
      organization: @organization,
      name: "Piso 1",
      section_type: SectionTypes::FLOOR,
      parent: @tower
    )

    post move_admin_residential_property_property_section_path(@property, floor), params: {
      property_section: { parent_id: tower_b.id }
    }

    assert_equal tower_b.id, floor.reload.parent_id
    assert_redirected_to @structure_path
  end

  # 9.21 / §7.5
  test "archive delegates to the service without a hard delete" do
    sign_in_as(@tenant_admin)

    post archive_admin_residential_property_property_section_path(@property, @tower)

    assert_equal SectionStatuses::ARCHIVED, @tower.reload.status
    assert PropertySection.exists?(@tower.id)
    assert_redirected_to @structure_path
  end

  # 9.20 / 9.21
  test "mutations are forbidden for users without manage_sections" do
    sign_in_as(@client)

    assert_no_difference -> { @property.property_sections.count } do
      post admin_residential_property_property_sections_path(@property), params: {
        property_section: { name: "Forbidden", section_type: SectionTypes::TOWER }
      }
    end
  end

  # §"Delete vs archive strategy": there is no administrative destroy route for
  # sections; archive is the only retirement path (nested or flat).
  test "no administrative destroy route exists for sections" do
    destroy_routes = Rails.application.routes.routes.select do |route|
      controller = route.defaults[:controller].to_s
      route.defaults[:action].to_s == "destroy" &&
        controller.in?(%w[admin/property_sections admin/residential_properties/property_sections])
    end

    assert_empty destroy_routes,
                 "expected no destroy route for property sections, found: #{destroy_routes.map(&:name)}"
  end

  # 9.22
  test "structure show exposes the tree DTO, catalogs and backend-driven permissions" do
    sign_in_as(@tenant_admin)

    inertia_get @structure_path
    props = inertia_props

    assert_equal "admin/residential_properties/structure", inertia_component
    assert props.key?("section_tree")
    assert_equal SectionTypes::ALL, props["section_types"]
    assert_equal SectionStatuses::ALL, props["section_statuses"]
    assert props.key?("parent_options")
    assert props.key?("structure_permissions")

    node = props["section_tree"].first
    assert node.key?("permissions")
    assert node["permissions"].key?("add_child")
    assert node.key?("effective_status")
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "password1" } }
  end
end
