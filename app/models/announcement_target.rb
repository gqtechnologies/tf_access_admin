# frozen_string_literal: true

# == Schema Information
#
# Table name: announcement_targets
#
#  id              :uuid             not null, primary key
#  target_rule     :jsonb            not null
#  target_type     :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  announcement_id :uuid             not null
#  organization_id :uuid             not null
#  target_id       :uuid             not null
#
# Indexes
#
#  idx_on_organization_id_announcement_id_fddacab166  (organization_id,announcement_id)
#  index_announcement_targets_on_announcement_id      (announcement_id)
#  index_announcement_targets_on_org_target           (organization_id,target_type,target_id)
#  index_announcement_targets_on_organization_id      (organization_id)
#  index_announcement_targets_on_target_rule          (target_rule) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (announcement_id => announcements.id)
#  fk_rails_...  (organization_id => organizations.id)
#
class AnnouncementTarget < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :announcement
  belongs_to :target, polymorphic: true
end
