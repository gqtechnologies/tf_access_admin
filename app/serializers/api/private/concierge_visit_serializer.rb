# frozen_string_literal: true

# Minimal visit payload for the mobile concierge listing and entry responses.
# Exposes the visitor's name and profile photo (identity is verified by eye at
# the door) and never their email, phone or document.
# `scope` is the current user, used to evaluate VisitPolicy.
class Api::Private::ConciergeVisitSerializer < ActiveModel::Serializer
  attributes :id, :status, :effective_status, :scheduled_at, :checked_in_at, :checked_out_at,
             :visitor, :unit, :authorized_by_name, :can_check_in, :can_check_out

  def effective_status
    object.effective_operational_status
  end

  def visitor
    { name: object.visitor_person&.display_name, avatar_url: visitor_avatar_url }
  end

  def unit
    unit = object.unit

    { display_name: unit&.display_name.presence || unit&.identifier }
  end

  def authorized_by_name
    object.authorized_by&.name
  end

  # may_check_in? runs the state machine guard too (validity window), so the app
  # never offers an entry the server would reject. The photo is mandatory on
  # this channel: without it there is nothing to verify the visitor against.
  def can_check_in
    visitor_avatar_url.present? && object.may_check_in? && policy.check_in?
  end

  def can_check_out
    object.may_check_out? && policy.check_out?
  end

  private

  def visitor_avatar_url
    return @visitor_avatar_url if defined?(@visitor_avatar_url)

    @visitor_avatar_url = object.visitor_person&.user&.avatar_path
  end

  def policy
    @policy ||= VisitPolicy.new(scope, object)
  end
end
