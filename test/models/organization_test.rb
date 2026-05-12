# == Schema Information
#
# Table name: organizations
#
#  id                        :uuid             not null, primary key
#  country_code              :string           default("CL"), not null
#  deleted_at                :datetime
#  legal_name                :string
#  metadata                  :jsonb            not null
#  name                      :string           not null
#  plan                      :string           default("free"), not null
#  settings                  :jsonb            not null
#  status                    :string           default("active"), not null
#  subdomain                 :string
#  tax_identifier_ciphertext :text
#  tax_identifier_digest     :string
#  tax_identifier_type       :string           default("rut"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  idx_organizations_unique_tax_identifier  (country_code,tax_identifier_type,tax_identifier_digest) UNIQUE WHERE ((tax_identifier_digest IS NOT NULL) AND (deleted_at IS NULL))
#  index_organizations_on_deleted_at        (deleted_at)
#  index_organizations_on_metadata          (metadata) USING gin
#  index_organizations_on_plan              (plan)
#  index_organizations_on_settings          (settings) USING gin
#  index_organizations_on_status            (status)
#  index_organizations_on_subdomain         (subdomain) UNIQUE
#
require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
