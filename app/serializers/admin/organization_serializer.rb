class Admin::OrganizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :subdomain, :cover_path, :logo_path, :users_count, :plan
end
