# frozen_string_literal: true

class Admin::OperationalRolesController < AdminController
  CAPABILITY_MODULES = [
    { module: "General", capabilities: [
      Authorization::Capabilities::MANAGE_ORGANIZATION,
      Authorization::Capabilities::MANAGE_USERS
    ] },
    { module: "Propiedades", capabilities: [
      Authorization::Capabilities::MANAGE_PROPERTIES,
      Authorization::Capabilities::MANAGE_PROPERTY,
      Authorization::Capabilities::MANAGE_SECTIONS
    ] },
    { module: "Unidades", capabilities: [
      Authorization::Capabilities::VIEW_UNITS,
      Authorization::Capabilities::MANAGE_UNITS
    ] },
    { module: "Personas", capabilities: [
      Authorization::Capabilities::VIEW_PEOPLE,
      Authorization::Capabilities::MANAGE_PEOPLE,
      Authorization::Capabilities::VIEW_SENSITIVE_PERSON_DATA
    ] },
    { module: "Propietarios", capabilities: [ Authorization::Capabilities::MANAGE_OWNERSHIPS ] },
    { module: "Residentes", capabilities: [ Authorization::Capabilities::MANAGE_OCCUPANCIES ] },
    { module: "Visitas", capabilities: [
      Authorization::Capabilities::VIEW_VISITS,
      Authorization::Capabilities::VIEW_AUTHORIZED_VISITS,
      Authorization::Capabilities::MANAGE_VISITS,
      Authorization::Capabilities::CREATE_VISITS,
      Authorization::Capabilities::AUTHORIZE_VISITS,
      Authorization::Capabilities::REGISTER_VISIT_ENTRY,
      Authorization::Capabilities::REGISTER_VISIT_EXIT,
      Authorization::Capabilities::VIEW_MINIMAL_ACCESS_CONTROL_DATA
    ] },
    { module: "Personal", capabilities: [ Authorization::Capabilities::MANAGE_STAFF_ASSIGNMENTS ] },
    { module: "Acceso propio", capabilities: [ Authorization::Capabilities::VIEW_OWN_UNIT_CONTEXT ] }
  ].freeze

  CAPABILITY_LABELS = {
    manage_organization: "Gestionar organización",
    manage_users: "Gestionar usuarios",
    manage_properties: "Gestionar propiedades",
    manage_property: "Gestionar propiedad",
    manage_sections: "Gestionar secciones",
    view_units: "Ver unidades",
    manage_units: "Gestionar unidades",
    view_people: "Ver personas",
    manage_people: "Gestionar personas",
    view_sensitive_person_data: "Ver datos sensibles",
    manage_ownerships: "Gestionar propietarios",
    manage_occupancies: "Gestionar residentes",
    view_visits: "Ver visitas",
    view_authorized_visits: "Ver visitas autorizadas",
    manage_visits: "Gestionar visitas",
    create_visits: "Crear visitas",
    authorize_visits: "Autorizar visitas",
    register_visit_entry: "Registrar entrada",
    register_visit_exit: "Registrar salida",
    view_minimal_access_control_data: "Ver datos de control de acceso",
    view_own_unit_context: "Ver contexto de unidad propia",
    manage_staff_assignments: "Gestionar asignaciones de personal"
  }.freeze

  def index
    authorize nil, :index?, policy_class: OperationalRolePolicy

    assignments_scope = scoped_assignments.includes(:person, :residential_property)

    roles_with_counts = OperationalRoles::RoleDefinitions.all.map do |role|
      users_count = assignments_scope.where(staff_type: role[:staff_types])
                                     .select(:person_id).distinct.count
      role.slice(:key, :name, :description, :scope).merge(users_count: users_count)
    end

    render inertia: "admin/operational_roles/index", props: {
      roles: roles_with_counts,
      summary: {
        defined_roles_count: OperationalRoles::RoleDefinitions.all.size,
        total_assignments_count: assignments_scope.count,
        properties_with_assignments: assignments_scope.select(:residential_property_id).distinct.count
      },
      capability_matrix: build_capability_matrix,
      permissions: {
        manage: operational_role_policy.create?
      }
    }
  end

  def show
    authorize nil, :show?, policy_class: OperationalRolePolicy

    role = OperationalRoles::RoleDefinitions.find(params[:role])
    return redirect_to admin_operational_roles_path unless role

    assignments_scope = scoped_assignments
      .where(staff_type: role[:staff_types])
      .includes(:person, :residential_property)

    users = assignments_scope.map do |a|
      {
        assignment_id: a.id,
        person_id: a.person_id,
        person_name: a.person&.display_name,
        property_id: a.residential_property_id,
        property_name: a.residential_property&.name,
        starts_at: a.starts_at,
        ends_at: a.ends_at
      }
    end

    render inertia: "admin/operational_roles/show", props: {
      role: role.slice(:key, :name, :description, :scope).merge(
        capabilities: role[:capabilities].map(&:to_s),
        users_count: users.size
      ),
      users: users,
      capability_groups: grouped_capabilities_for_role(role),
      permissions: {
        manage: operational_role_policy.create?
      }
    }
  end

  private

  def operational_role_policy
    OperationalRolePolicy.new(current_user, nil)
  end

  def scoped_assignments
    base = Authorization::Resolver.new(user: current_user, organization: Current.organization)
    if base.profile.organization_wide?
      StaffAssignment.currently_active
    else
      StaffAssignment.currently_active.where(residential_property_id: base.accessible_property_ids)
    end
  end

  def build_capability_matrix
    all_roles = OperationalRoles::RoleDefinitions.all_for_matrix
    CAPABILITY_MODULES.map do |group|
      {
        module: group[:module],
        capabilities: group[:capabilities].map do |cap|
          {
            key: cap.to_s,
            label: CAPABILITY_LABELS[cap] || cap.to_s.humanize,
            roles: all_roles.each_with_object({}) { |role, h| h[role[:key]] = role[:capabilities].include?(cap) }
          }
        end
      }
    end
  end

  def grouped_capabilities_for_role(role)
    CAPABILITY_MODULES.filter_map do |group|
      caps = group[:capabilities].map do |cap|
        {
          key: cap.to_s,
          label: CAPABILITY_LABELS[cap] || cap.to_s.humanize,
          granted: role[:capabilities].include?(cap)
        }
      end
      { module: group[:module], capabilities: caps }
    end
  end
end
