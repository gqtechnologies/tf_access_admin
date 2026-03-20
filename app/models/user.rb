class User < ApplicationRecord
  rolify
  acts_as_paranoid

  has_many :permissions, through: :roles
  has_one_attached :avatar
  
  acts_as_tenant(:organization)
  belongs_to :organization

  after_create :assign_default_role

  validates :name, presence: true
  validates :dni, presence: true
  validates :language, presence: true, inclusion: { in: Languages::ALL }
  validates :email, uniqueness: { message: "admin.users.validations.email_taken" }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Sin :registerable: el alta de usuarios es vía admin; evita rutas/métodos de sign_up público
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable,
         :confirmable
  def role
    return nil if roles.blank?
    roles.min_by { |r| AvailableRoles.priority_index(r.name, :global) }.name
  end

  def tenant_role
    return nil if roles.blank?
    roles.min_by { |r| AvailableRoles.priority_index(r.name, :tenant) }.name
  end

  def super_admin?
    has_role?(AvailableRoles::SUPER_ADMIN)
  end

  def tenant_admin?(tenant = self.organization)
    has_role?(AvailableRoles::TENANT_ADMIN, tenant)
  end

  def set_tenant_role(role)
    removed = delete_tenant_roles

    self.add_role(role, self.organization) unless has_role?(role, self.organization)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["name", "email", "dni"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
  
  private
  def assign_default_role
    self.add_role(:client, self.organization) if self.roles.blank?
  end

  def delete_tenant_roles
    return [] if roles.blank?

    tenant_roles = roles.select do |r|
      r.resource_type == "Organization" && r.resource_id == organization_id
    end

    role_names = tenant_roles.map(&:name)
    role_names.each { |name| remove_role(name, organization) }
    role_names
  end
end
