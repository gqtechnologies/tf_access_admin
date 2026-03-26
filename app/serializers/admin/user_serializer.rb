class Admin::UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :dni, :language, :avatar_path, :avatar_filename, :role, :tenant_role

  def avatar_filename
    return nil unless object.avatar.attached?

    object.avatar.filename.to_s
  end

  def role
    object.role
  end

  def tenant_role
    object.tenant_role
  end
end
