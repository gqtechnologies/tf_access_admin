class User < ApplicationRecord
  rolify
  acts_as_paranoid
  include Users::Features

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
         :confirmable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  def jwt_payload
    {
      "organization_id" => organization_id.to_s
    }
  end

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

  def client_global?
    has_role?(AvailableRoles::CLIENT)
  end

  def tenant_admin?(tenant = self.organization)
    has_role?(AvailableRoles::TENANT_ADMIN, tenant)
  end

  def set_tenant_role(role)
    removed = delete_tenant_roles

    self.add_role(role, self.organization) unless has_role?(role, self.organization)
  end

  def avatar_path
    BlobUrls.url_for(avatar)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["name", "email", "dni"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private
  def assign_default_role
    # client roles is a global role, so it should be assigned to the user without organization
    self.add_role(:client) if self.roles.blank?
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
