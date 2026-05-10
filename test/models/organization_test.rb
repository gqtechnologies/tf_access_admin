# == Schema Information
#
# Table name: organizations
#
#  id         :uuid             not null, primary key
#  deleted_at :datetime
#  name       :string
#  plan       :string           default("free"), not null
#  subdomain  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organizations_on_deleted_at  (deleted_at)
#  index_organizations_on_plan        (plan)
#  index_organizations_on_subdomain   (subdomain) UNIQUE
#
require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
