# frozen_string_literal: true

# Custom Audited model so each row gets +organization_id+ for tenant-safe queries.
# User remains polymorphic (+user_id+ / +user_type+) as required by Audited.
# == Schema Information
#
# Table name: audits
#
#  id              :uuid             not null, primary key
#  action          :string
#  associated_type :string
#  auditable_type  :string
#  audited_changes :text
#  comment         :string
#  remote_address  :string
#  request_uuid    :string
#  user_type       :string
#  username        :string
#  version         :integer          default(0)
#  created_at      :datetime
#  associated_id   :uuid
#  auditable_id    :uuid
#  organization_id :uuid
#  user_id         :uuid
#
# Indexes
#
#  associated_index                          (associated_type,associated_id)
#  auditable_index                           (auditable_type,auditable_id,version)
#  index_audits_on_auditable_org_version     (auditable_type,auditable_id,organization_id,version)
#  index_audits_on_created_at                (created_at)
#  index_audits_on_org_auditable_created_at  (organization_id,auditable_type,auditable_id,created_at)
#  index_audits_on_organization_id           (organization_id)
#  index_audits_on_request_uuid              (request_uuid)
#  user_index                                (user_id,user_type)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#
class TenantAudit < Audited::Audit
  self.table_name = "audits"

  belongs_to :organization, optional: true

  before_create :assign_organization_id

  private

  def assign_organization_id
    return if organization_id.present?

    self.organization_id =
      Current.organization&.id ||
        ActsAsTenant.current_tenant&.id ||
        (auditable.organization_id if auditable&.respond_to?(:organization_id)) ||
        (auditable.id if auditable.is_a?(Organization))
  end
end
