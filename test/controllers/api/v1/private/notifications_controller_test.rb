# frozen_string_literal: true

require "test_helper"

# /api/v1/private/notifications — OpenSpec 2026-10-02-mobile-notifications.
class Api::V1::Private::NotificationsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include ParcelTestHelper
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    setup_parcel_world("NT")
    @parcel = Parcels::Receive.call(unit: @unit, actor: @concierge, attributes: { delivery_type: "food" })
    @mine = @parcel.notifications.find_by!(recipient_person: person_of(@picker))
    @theirs = @parcel.notifications.find_by!(recipient_person: person_of(@relative))
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "lists my notifications rendered like the push, newest first" do
    older = Parcels::Receive.call(unit: @unit, actor: @concierge)
                            .notifications.find_by!(recipient_person: person_of(@picker))
    older.update_columns(created_at: 2.days.ago)

    request_as(@picker) { get api_v1_private_notifications_path, headers: JSON_HEADERS }

    assert_response :ok
    body = response.parsed_body
    assert_equal [ @mine.id, older.id ], body["data"].map { |n| n["id"] }
    assert_equal 2, body["unread_count"]
    assert_equal 2, body.dig("pagination", "total_count")

    first = body["data"].first
    assert_equal "parcel", first["type"]
    assert_equal I18n.t("notifications.parcel.title", locale: :es), first["title"]
    assert_includes first["body"], "NT-P-101"
    assert_equal @unit.id, first.dig("data", "unit_id")
    assert_equal false, first["read"]
  end

  test "does not list notifications older than the window" do
    @mine.update_columns(created_at: 61.days.ago)

    request_as(@picker) { get api_v1_private_notifications_path, headers: JSON_HEADERS }

    assert_empty response.parsed_body["data"]
    assert_equal 0, response.parsed_body["unread_count"]
  end

  test "read marks one notification and returns the remaining count" do
    request_as(@picker) { post read_api_v1_private_notification_path(@mine), headers: JSON_HEADERS }

    assert_response :ok
    assert_equal 0, response.parsed_body["unread_count"]
    assert @mine.reload.read_at.present?
    assert_nil @theirs.reload.read_at
  end

  test "read keeps the first read time" do
    @mine.update_columns(read_at: 1.day.ago)
    first_read = @mine.reload.read_at

    request_as(@picker) { post read_api_v1_private_notification_path(@mine), headers: JSON_HEADERS }

    assert_equal first_read.to_i, @mine.reload.read_at.to_i
  end

  test "someone else's notification is not found" do
    request_as(@picker) { post read_api_v1_private_notification_path(@theirs), headers: JSON_HEADERS }

    assert_response :not_found
    assert_nil @theirs.reload.read_at
  end

  test "read_all marks only my notifications" do
    Parcels::Receive.call(unit: @unit, actor: @concierge)

    request_as(@picker) { post read_all_api_v1_private_notifications_path, headers: JSON_HEADERS }

    assert_response :ok
    assert_equal 0, response.parsed_body["unread_count"]
    assert_equal 0, Notification.where(recipient_person: person_of(@picker), read_at: nil).count
    assert_equal 2, Notification.where(recipient_person: person_of(@relative), read_at: nil).count
  end

  test "member without notifications gets an empty inbox" do
    request_as(@concierge) { get api_v1_private_notifications_path, headers: JSON_HEADERS }

    assert_response :ok
    assert_empty response.parsed_body["data"]
    assert_equal 0, response.parsed_body["unread_count"]
  end

  test "requires authentication" do
    host! "#{@organization.subdomain}.example.com"
    get api_v1_private_notifications_path, headers: JSON_HEADERS

    assert_response :unauthorized
  end

  private

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end
end
