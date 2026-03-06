module AvailableRoles
    SUPER_ADMIN = "super_admin".freeze
    TENANT_ADMIN = "tenant_admin".freeze
    MANAGER = "manager".freeze
    CLIENT = "client".freeze
    CONTENT_MANAGER = "content_manager".freeze
  
    GLOBAL = [
      SUPER_ADMIN
    ].freeze
  
    TENANT = [
      TENANT_ADMIN,
      MANAGER,
      CLIENT,
    ].freeze
  
    RESOURCE = [
        CONTENT_MANAGER
    ].freeze
  
    ALL = (GLOBAL + TENANT + RESOURCE).freeze
  end