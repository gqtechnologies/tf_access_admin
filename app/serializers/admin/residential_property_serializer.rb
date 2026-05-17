# frozen_string_literal: true

class Admin::ResidentialPropertySerializer < ActiveModel::Serializer
  attributes :id, :name, :code, :property_type, :address_line, :city, :region, :country,
             :timezone, :status, :metadata, :organization_id, :created_at, :updated_at
end
