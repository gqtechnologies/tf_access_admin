# frozen_string_literal: true

# == Schema Information
#
# Table name: visitor_profiles
#
#  id                         :uuid             not null, primary key
#  company_name               :string
#  deleted_at                 :datetime
#  document_number_ciphertext :text
#  document_number_digest     :string
#  document_type              :string
#  email_ciphertext           :text
#  external_name              :string
#  metadata                   :jsonb            not null
#  phone_ciphertext           :text
#  security_notes             :text
#  status                     :string           default("active"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  organization_id            :uuid             not null
#  person_id                  :uuid
#
# Indexes
#
#  index_visitor_profiles_on_deleted_at                           (deleted_at)
#  index_visitor_profiles_on_metadata                             (metadata) USING gin
#  index_visitor_profiles_on_organization_id                      (organization_id)
#  index_visitor_profiles_on_organization_id_and_person_id        (organization_id,person_id)
#  index_visitor_profiles_on_organization_id_and_status           (organization_id,status)
#  index_visitor_profiles_on_person_id                            (person_id)
#  index_visitor_profiles_unique_doc_digest_per_org_when_present  (organization_id,document_number_digest) UNIQUE WHERE ((deleted_at IS NULL) AND (document_number_digest IS NOT NULL))
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#
class VisitorProfile < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization
  acts_as_paranoid

  belongs_to :organization
  belongs_to :person, optional: true

  validates_same_tenant :person
end
