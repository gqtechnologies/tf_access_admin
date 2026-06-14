# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "User must be logged in" unless user

    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def admin?
    user.present? && (user.super_admin? || user.tenant_admin?(ActsAsTenant.current_tenant))
  end

  def super_admin?
    user.present? && user.super_admin?
  end

  def same_organization?
    return false unless user.present?
    return true if user.super_admin?

    tenant = ActsAsTenant.current_tenant
    return false unless tenant&.id
    return false if user.client_global? && !user.tenant_admin?(tenant)

    if record.is_a?(User)
      user.people.exists?(organization_id: tenant.id) && record.people.exists?(organization_id: tenant.id)
    elsif record.respond_to?(:organization_id)
      record.organization_id == tenant.id && user.people.exists?(organization_id: tenant.id)
    else
      true
    end
  end

  def same_user?
    return false unless user.present?
    return false unless record.respond_to?(:id)
    return false unless user.respond_to?(:id)
    record.id == user.id
  end

  class Scope
    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, "User must be logged in" unless user
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
