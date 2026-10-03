# frozen_string_literal: true

# Administration of announcements: list per property and status, write and
# edit drafts, publish (which pushes them to the property's residents) and
# archive. One Inertia page with drawers, like the front-desk parcels page.
class Admin::AnnouncementsController < AdminController
  TABS = AnnouncementStatuses::ALL

  before_action :set_announcement, only: %i[update publish archive]

  def index
    authorize Announcement

    scoped = property_scoped
    announcements = scoped.where(status: tab)
                          .includes(:author_person)
                          .order(Arel.sql("COALESCE(announcements.published_at, announcements.created_at) DESC"))
                          .page(@filters[:page])
                          .per(@filters[:per_page])
    stats = read_stats(announcements.map(&:id))

    render inertia: "admin/announcements/index", props: {
      announcements: announcements.map { |announcement| serialize(announcement, stats[announcement.id]) },
      pagination: pagination_info(announcements),
      tab: tab,
      counters: TABS.index_with { |status| scoped.where(status: status).count },
      properties: managed_properties.map { |property| { id: property.id, name: property.name } },
      active_property: active_property && { id: active_property.id, name: active_property.name },
      audience_count: active_property ? Authorization::ActiveRelationships.active_person_ids_of_property(active_property).size : 0,
      categories: AnnouncementCategories::ALL,
      priorities: Priorities::ALL
    }
  end

  def create
    return redirect_with_errors({ base: [ t("frontend.admin.announcements.errors.no_property") ] }) unless active_property

    announcement = Announcement.new(
      announcement_params.merge(
        organization: Current.organization,
        residential_property: active_property,
        author_person: current_user.person_for(Current.organization),
        status: AnnouncementStatuses::DRAFT
      )
    )
    authorize announcement

    if announcement.save
      redirect_to list_path(tab: AnnouncementStatuses::DRAFT)
    else
      redirect_with_errors(serialize_inertia_errors(announcement), tab: AnnouncementStatuses::DRAFT)
    end
  end

  def update
    authorize @announcement

    if @announcement.update(announcement_params)
      redirect_to list_path(tab: AnnouncementStatuses::DRAFT)
    else
      redirect_with_errors(serialize_inertia_errors(@announcement), tab: AnnouncementStatuses::DRAFT)
    end
  end

  def publish
    Announcements::Publish.call(announcement: @announcement, actor: current_user)
    redirect_to list_path(tab: AnnouncementStatuses::PUBLISHED)
  rescue Pundit::NotAuthorizedError
    redirect_with_errors({ base: [ t("frontend.admin.announcements.errors.not_publishable") ] })
  end

  def archive
    Announcements::Archive.call(announcement: @announcement, actor: current_user)
    redirect_to list_path(tab: AnnouncementStatuses::ARCHIVED)
  rescue Pundit::NotAuthorizedError
    redirect_with_errors({ base: [ t("frontend.admin.announcements.errors.not_archivable") ] })
  end

  private

  def set_announcement
    @announcement = policy_scope(Announcement).find(params[:id])
    @active_property = @announcement.residential_property
  rescue ActiveRecord::RecordNotFound
    redirect_with_errors({ base: [ t("frontend.admin.announcements.errors.not_found") ] })
  end

  def tab
    TABS.include?(params[:tab].to_s) ? params[:tab].to_s : AnnouncementStatuses::PUBLISHED
  end

  # Properties where the actor holds manage_announcements: all of them for an
  # organization-wide holder, the managed ones for a property admin.
  def managed_properties
    @managed_properties ||= begin
      profile = Authorization::Resolver.new(user: current_user, organization: Current.organization).profile

      if profile.organization_capabilities.include?(Authorization::Capabilities::MANAGE_ANNOUNCEMENTS)
        ResidentialProperty.order(:name).to_a
      else
        ids = profile.property_capabilities
                     .select { |_, caps| caps.include?(Authorization::Capabilities::MANAGE_ANNOUNCEMENTS) }
                     .keys
        ResidentialProperty.where(id: ids).order(:name).to_a
      end
    end
  end

  def active_property
    @active_property ||= managed_properties.find { |property| property.id.to_s == params[:property_id].to_s } ||
                         managed_properties.first
  end

  def property_scoped
    return policy_scope(Announcement).none unless active_property

    policy_scope(Announcement).where(residential_property_id: active_property.id)
  end

  # read / acknowledged counts per announcement, in two grouped queries.
  def read_stats(ids)
    reads = AnnouncementRead.where(announcement_id: ids)
    read_counts = reads.where.not(read_at: nil).group(:announcement_id).count
    ack_counts = reads.where.not(acknowledged_at: nil).group(:announcement_id).count

    ids.index_with { |id| { read: read_counts[id] || 0, acknowledged: ack_counts[id] || 0 } }
  end

  def serialize(announcement, stats)
    {
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      category: announcement.category,
      priority: announcement.priority,
      status: announcement.status,
      requires_acknowledgement: announcement.requires_acknowledgement?,
      published_at: announcement.published_at,
      expires_at: announcement.expires_at,
      created_at: announcement.created_at,
      author_name: announcement.author_person&.display_name,
      read_count: stats&.dig(:read) || 0,
      acknowledged_count: stats&.dig(:acknowledged) || 0
    }
  end

  def announcement_params
    params.fetch(:announcement, {}).permit(:title, :content, :category, :priority, :requires_acknowledgement, :expires_at)
  end

  def list_path(tab: nil)
    admin_announcements_path({ property_id: active_property&.id, tab: tab }.compact)
  end

  def redirect_with_errors(errors, tab: nil)
    redirect_to list_path(tab: tab || params[:tab].presence), inertia: { errors: errors }
  end
end
