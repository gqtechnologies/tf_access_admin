# frozen_string_literal: true

module OperationalRoles
  module RoleDefinitions
    ROLES = [
      {
        key: "property_admin",
        name: "Administrador de propiedad",
        description: "Gestiona unidades, personas, residentes, propietarios y personal de la propiedad.",
        scope: "property",
        staff_types: [StaffTypes::MANAGER],
        capabilities: Authorization::Capabilities::PROPERTY_ADMIN
      },
      {
        key: "concierge",
        name: "Conserje / Portería",
        description: "Registra entradas y salidas de visitas autorizadas en la propiedad.",
        scope: "property",
        staff_types: [StaffTypes::CONCIERGE, StaffTypes::SECURITY],
        capabilities: Authorization::Capabilities::CONCIERGE
      },
      {
        key: "cleaning_staff",
        name: "Personal de aseo",
        description: "Personal de aseo asignado a la propiedad.",
        scope: "property",
        staff_types: [StaffTypes::CLEANING],
        capabilities: Authorization::Capabilities::CLEANING_STAFF
      },
      {
        key: "internal_staff",
        name: "Personal interno",
        description: "Personal interno con acceso limitado según función asignada.",
        scope: "property",
        staff_types: [StaffTypes::MAINTENANCE, StaffTypes::OTHER],
        capabilities: Authorization::Capabilities::INTERNAL_STAFF
      }
    ].freeze

    ORG_ROLES = [
      {
        key: "tenant_admin",
        name: "Administrador de organización",
        description: "Acceso completo a toda la organización.",
        scope: "organization",
        staff_types: [],
        capabilities: Authorization::Capabilities::ORGANIZATION_ADMIN
      },
      {
        key: "content_manager",
        name: "Gestor de contenido",
        description: "Gestión de propiedades, unidades y personas sin acceso administrativo.",
        scope: "organization",
        staff_types: [],
        capabilities: Authorization::Capabilities::CONTENT_MANAGER
      }
    ].freeze

    module_function

    def all
      ROLES
    end

    def find(key)
      ROLES.find { |r| r[:key] == key.to_s }
    end

    def all_for_matrix
      ORG_ROLES + ROLES
    end
  end
end
