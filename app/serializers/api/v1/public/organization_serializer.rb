# frozen_string_literal: true

class Api::V1::Public::OrganizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :slug, :cover, :logo

  def slug
    object.subdomain
  end

  def cover
    object.cover_path
  end

  def logo
    object.logo_path
  end
end
