# frozen_string_literal: true

Audited.config do |config|
  config.audit_class = "TenantAudit"
  # Devise + Pundit convention in this app
  config.current_user_method = :current_user
end
