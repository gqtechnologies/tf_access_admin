# frozen_string_literal: true

class Person < ApplicationRecord
  acts_as_tenant :organization
  acts_as_paranoid
  rolify

  belongs_to :organization
  belongs_to :user, optional: true
  has_one :organization_membership, dependent: :destroy

  validates :display_name, presence: true

  def set_tenant_role(role_name)
    delete_tenant_roles
    add_role(role_name, organization) unless has_role?(role_name, organization)
  end

  private

  def delete_tenant_roles
    return [] if roles.blank?

    tenant_roles = roles.select do |r|
      r.resource_type == "Organization" && r.resource_id == organization_id.to_s
    end

    role_names = tenant_roles.map(&:name)
    role_names.each { |name| remove_role(name, organization) }
    role_names
  end
end
