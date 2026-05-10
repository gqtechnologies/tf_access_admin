# == Schema Information
#
# Table name: roles
#
#  id              :uuid             not null, primary key
#  name            :string
#  resource_type   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :uuid
#  resource_id     :string
#
# Indexes
#
#  index_roles_on_name                                    (name)
#  index_roles_on_name_and_resource_type_and_resource_id  (name,resource_type,resource_id)
#  index_roles_on_organization_id                         (organization_id)
#  index_roles_on_resource                                (resource_type,resource_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#
require "test_helper"

class RoleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
