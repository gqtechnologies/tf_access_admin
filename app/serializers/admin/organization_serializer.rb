class Admin::OrganizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :subdomain, :cover_path, :logo_path

  def cover_path
    return nil unless object.cover.attached?

    Rails.application.routes.url_helpers.rails_blob_path(
      object.cover,
      only_path: true
    )
  end

  def logo_path
    return nil unless object.logo.attached?

    Rails.application.routes.url_helpers.rails_blob_path(
      object.logo,
      only_path: true
    )
  end
end
