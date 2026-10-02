# frozen_string_literal: true

# GET  /api/v1/private/notifications?page=
# POST /api/v1/private/notifications/:id/read
# POST /api/v1/private/notifications/read_all
#
# In-app inbox. Lists the push notifications addressed to the current person in
# this organization over the last 60 days — whether or not the push itself was
# delivered — rendered with the same title/body/data as the push, so the app
# routes a tapped row exactly like a tapped push.
class Api::V1::Private::NotificationsController < Api::V1::Private::BaseController
  WINDOW = 60.days
  PER_PAGE = 25

  def index
    notifications = inbox.includes(:notifiable, :unit, :residential_property, recipient_person: :user)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(PER_PAGE)

    render json: {
      data: notifications.filter_map { |notification| serialize(notification) },
      unread_count: inbox.where(read_at: nil).count,
      pagination: {
        page: notifications.current_page,
        total_pages: notifications.total_pages,
        total_count: notifications.total_count
      }
    }, status: :ok
  end

  def read
    notification = inbox.find(params[:id])
    notification.update!(read_at: Time.zone.now) if notification.read_at.nil?

    render json: { unread_count: inbox.where(read_at: nil).count }, status: :ok
  end

  def read_all
    inbox.where(read_at: nil).update_all(read_at: Time.zone.now, updated_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations

    render json: { unread_count: 0 }, status: :ok
  end

  private

  # Someone else's notification is simply not in this relation → 404 on find.
  def inbox
    person = current_user.person_for(ActsAsTenant.current_tenant)
    return Notification.none if person.blank?

    Notification.where(recipient_person_id: person.id, channel: NotificationChannels::PUSH)
                .where(created_at: WINDOW.ago..)
  end

  # A notification whose subject can no longer be rendered (e.g. its visit was
  # removed) is left out rather than failing the whole page.
  def serialize(notification)
    payload = I18n.with_locale(locale_for_user) { Notifications::PushPayload.build(notification) }

    {
      id: notification.id,
      type: notification.notification_type,
      title: payload[:title],
      body: payload[:body],
      data: payload[:data],
      read: notification.read_at.present?,
      created_at: notification.created_at
    }
  rescue StandardError => e
    Rails.logger.warn("[NotificationsController] notification=#{notification.id} #{e.class}: #{e.message}")
    nil
  end

  def locale_for_user
    language = current_user.language.to_s
    I18n.available_locales.map(&:to_s).include?(language) ? language : I18n.default_locale
  end
end
