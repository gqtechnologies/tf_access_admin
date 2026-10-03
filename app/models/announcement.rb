# frozen_string_literal: true

# == Schema Information
#
# Table name: announcements
#
#  id                       :uuid             not null, primary key
#  category                 :string
#  content                  :text             not null
#  deleted_at               :datetime
#  expires_at               :datetime
#  metadata                 :jsonb            not null
#  priority                 :string           default("normal"), not null
#  published_at             :datetime
#  requires_acknowledgement :boolean          default(FALSE)
#  status                   :string           default("draft"), not null
#  title                    :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  author_person_id         :uuid             not null
#  organization_id          :uuid             not null
#  residential_property_id  :uuid             not null
#
# Indexes
#
#  index_announcements_on_author_person_id                      (author_person_id)
#  index_announcements_on_deleted_at                            (deleted_at)
#  index_announcements_on_metadata                              (metadata) USING gin
#  index_announcements_on_org_property_status_published_at      (organization_id,residential_property_id,status,published_at)
#  index_announcements_on_organization_id                       (organization_id)
#  index_announcements_on_organization_id_and_author_person_id  (organization_id,author_person_id)
#  index_announcements_on_organization_id_and_priority          (organization_id,priority)
#  index_announcements_on_residential_property_id               (residential_property_id)
#
# Foreign Keys
#
#  fk_rails_...  (author_person_id => people.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#
class Announcement < ApplicationRecord
  acts_as_paranoid
  include AnnouncementCategories
  include AnnouncementStatuses
  include Priorities
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :author_person, class_name: "Person"

  has_many :announcement_targets, dependent: :destroy
  has_many :announcement_reads, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  normalizes :title, :content, with: ->(value) { value.to_s.strip }

  # What residents see: published and not yet expired.
  scope :visible, lambda { |at: Time.zone.now|
    where(status: AnnouncementStatuses::PUBLISHED)
      .where(published_at: ..at)
      .where("announcements.expires_at IS NULL OR announcements.expires_at > ?", at)
  }

  def draft?
    status == AnnouncementStatuses::DRAFT
  end

  def published?
    status == AnnouncementStatuses::PUBLISHED
  end

  validates :priority, presence: true, inclusion: { in: Priorities::ALL }
  validates :status, presence: true, inclusion: { in: AnnouncementStatuses::ALL }
  validates :title, presence: true, length: { maximum: 150 }
  validates :content, presence: true, length: { maximum: 5000 }
  validate :expires_after_publication
  validates :category, inclusion: { in: AnnouncementCategories::ALL }, allow_nil: true, if: -> { category.present? }

  validates_same_tenant :residential_property, :author_person

  private

  def expires_after_publication
    return if expires_at.blank?
    return if expires_at > (published_at || Time.zone.now)

    errors.add(:expires_at, :invalid)
  end
end
