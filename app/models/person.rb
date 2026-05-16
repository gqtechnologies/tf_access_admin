# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id                         :uuid             not null, primary key
#  birthdate                  :date
#  deleted_at                 :datetime
#  display_name               :string           not null
#  document_number_ciphertext :text
#  document_number_digest     :string
#  document_type              :string
#  email_ciphertext           :text
#  first_name                 :string
#  last_name                  :string
#  metadata                   :jsonb            not null
#  person_type                :string           default("natural"), not null
#  phone_ciphertext           :text
#  status                     :string           default("active"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  organization_id            :uuid             not null
#  user_id                    :uuid
#
# Indexes
#
#  idx_people_unique_document_per_org_when_present   (organization_id,document_type,document_number_digest) UNIQUE WHERE ((document_number_digest IS NOT NULL) AND (deleted_at IS NULL))
#  idx_people_unique_user_per_org_when_present       (organization_id,user_id) UNIQUE WHERE ((user_id IS NOT NULL) AND (deleted_at IS NULL))
#  index_people_on_deleted_at                        (deleted_at)
#  index_people_on_metadata                          (metadata) USING gin
#  index_people_on_organization_id                   (organization_id)
#  index_people_on_organization_id_and_display_name  (organization_id,display_name)
#  index_people_on_organization_id_and_status        (organization_id,status)
#  index_people_on_organization_id_and_user_id       (organization_id,user_id)
#  index_people_on_user_id                           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#
class Person < ApplicationRecord
  include PersonTypes

  acts_as_tenant :organization
  acts_as_paranoid
  rolify

  belongs_to :organization
  belongs_to :user, optional: true
  has_one :organization_membership, dependent: :destroy

  validates :display_name, presence: true
  validates :person_type, presence: true, inclusion: { in: PersonTypes::ALL }

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
