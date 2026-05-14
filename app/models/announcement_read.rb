# frozen_string_literal: true

# == Schema Information
#
# Table name: announcement_reads
#
#  id              :uuid             not null, primary key
#  acknowledged_at :datetime
#  channel         :string
#  device_info     :jsonb            not null
#  metadata        :jsonb            not null
#  notified_at     :datetime
#  read_at         :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  announcement_id :uuid             not null
#  organization_id :uuid             not null
#  person_id       :uuid
#
# Indexes
#
#  index_announcement_reads_on_announcement_id              (announcement_id)
#  index_announcement_reads_on_device_info                  (device_info) USING gin
#  index_announcement_reads_on_metadata                     (metadata) USING gin
#  index_announcement_reads_on_org_announcement_read_at     (organization_id,announcement_id,read_at)
#  index_announcement_reads_on_org_person_read_at           (organization_id,person_id,read_at)
#  index_announcement_reads_on_organization_id              (organization_id)
#  index_announcement_reads_on_person_id                    (person_id)
#  index_announcement_reads_unique_per_person_when_present  (organization_id,announcement_id,person_id) UNIQUE WHERE (person_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (announcement_id => announcements.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#
class AnnouncementRead < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :announcement
  belongs_to :person, optional: true
end
