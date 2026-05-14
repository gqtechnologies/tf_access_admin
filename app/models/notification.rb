# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                      :uuid             not null, primary key
#  attempts_count          :integer          default(0), not null
#  channel                 :string           not null
#  last_error              :text
#  metadata                :jsonb            not null
#  notifiable_type         :string           not null
#  notification_type       :string           not null
#  read_at                 :datetime
#  sent_at                 :datetime
#  status                  :string           default("pending"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  notifiable_id           :uuid             not null
#  organization_id         :uuid             not null
#  recipient_person_id     :uuid             not null
#  residential_property_id :uuid
#  unit_id                 :uuid
#
# Indexes
#
#  index_notifications_on_metadata                         (metadata) USING gin
#  index_notifications_on_org_channel_pending_status       (organization_id,channel,status,created_at) WHERE ((status)::text = 'pending'::text)
#  index_notifications_on_org_notifiable                   (organization_id,notifiable_type,notifiable_id)
#  index_notifications_on_org_recipient_status_created_at  (organization_id,recipient_person_id,status,created_at)
#  index_notifications_on_organization_id                  (organization_id)
#  index_notifications_on_recipient_person_id              (recipient_person_id)
#  index_notifications_on_residential_property_id          (residential_property_id)
#  index_notifications_on_unit_id                          (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (recipient_person_id => people.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#  fk_rails_...  (unit_id => units.id)
#
class Notification < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property, optional: true
  belongs_to :unit, optional: true
  belongs_to :recipient_person, class_name: "Person"
  belongs_to :notifiable, polymorphic: true
end
