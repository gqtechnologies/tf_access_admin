# frozen_string_literal: true

class Admin::OperationalAssignmentRowSerializer < ActiveModel::Serializer
  attributes :id, :person_id, :person_name, :role, :role_key, :staff_type,
             :residential_property_id, :property_name, :status, :starts_at, :ends_at

  def person_name
    object.person&.display_name
  end

  def role
    role_name = Authorization::StaffRoleMapper.operational_role_for(object.staff_type)
    OperationalRoles::RoleDefinitions.find(role_name)&.dig(:name) || role_name
  end

  def role_key
    Authorization::StaffRoleMapper.operational_role_for(object.staff_type)
  end

  def property_name
    object.residential_property&.name
  end
end
