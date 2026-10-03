# frozen_string_literal: true

# GET  /api/v1/private/announcements
# GET  /api/v1/private/announcements/:id
# POST /api/v1/private/announcements/:id/acknowledge
#
# The administration's announcements as residents see them: published, not
# expired, for the properties where the person holds a currently valid
# occupancy or ownership. Opening one records the read; announcements that
# require it can be acknowledged ("I've read it").
class Api::V1::Private::AnnouncementsController < Api::V1::Private::BaseController
  LIMIT = 50

  before_action :load_announcement, only: %i[show acknowledge]

  def index
    announcements = visible.order(published_at: :desc).limit(LIMIT).to_a
    reads = person ? AnnouncementRead.where(person_id: person.id, announcement_id: announcements.map(&:id)).index_by(&:announcement_id) : {}

    render json: {
      data: announcements.map { |announcement| serialize(announcement, reads[announcement.id]) },
      unread_count: announcements.count { |announcement| reads[announcement.id]&.read_at.blank? }
    }, status: :ok
  end

  def show
    read = record_read
    read.update!(read_at: Time.zone.now) if read.read_at.blank?

    render json: { data: serialize(@announcement, read) }, status: :ok
  end

  def acknowledge
    unless @announcement.requires_acknowledgement?
      return render json: { error: I18n.t("api.announcements.no_acknowledgement") }, status: :unprocessable_entity
    end

    read = record_read
    now = Time.zone.now
    read.update!(read_at: read.read_at || now, acknowledged_at: read.acknowledged_at || now)

    render json: { data: serialize(@announcement, read) }, status: :ok
  end

  private

  def person
    @person ||= current_user.person_for(ActsAsTenant.current_tenant)
  end

  # Properties where the person has a currently valid unit relationship.
  def property_ids
    return [] if person.blank?

    Unit.with_active_relationship_for(person, ActsAsTenant.current_tenant).distinct.pluck(:residential_property_id)
  end

  def visible
    Announcement.visible.where(residential_property_id: property_ids).includes(:residential_property)
  end

  # Not visible to this person (other property, draft, archived, expired) → 404.
  def load_announcement
    @announcement = visible.find(params[:id])
  end

  def record_read
    AnnouncementRead.find_or_create_by!(
      organization: @announcement.organization, announcement: @announcement, person: person
    ) { |read| read.channel = NotificationChannels::PUSH }
  end

  def serialize(announcement, read)
    {
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      category: announcement.category,
      priority: announcement.priority,
      published_at: announcement.published_at,
      expires_at: announcement.expires_at,
      requires_acknowledgement: announcement.requires_acknowledgement?,
      residential_property: { id: announcement.residential_property_id, name: announcement.residential_property.name },
      read: read&.read_at.present?,
      acknowledged: read&.acknowledged_at.present?
    }
  end
end
