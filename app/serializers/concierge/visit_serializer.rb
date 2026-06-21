# frozen_string_literal: true

# Operational list serializer for Visit, used in Concierge::VisitsController#index (§7.2, §7.3).
# Exposes only the fields needed for the concierge tabs (authorized/checked-in/recent checked-out):
# visitor identity, unit, host, status labels, relevant timestamps, and backend-computed actions.
# Administrative data (notes, metadata, full person profiles, actor stamps, history) are omitted.
class Concierge::VisitSerializer < ActiveModel::Serializer
  attributes :id,
    :status,
    :status_label,
    :visit_type,
    :visit_type_label,
    :scheduled_at,
    :valid_from,
    :authorized_at,
    :checked_in_at,
    :checked_out_at,
    :residential_property_id,
    :unit_id,
    :visitor_person_id,
    :host_person_id,
    :visitor,
    :host,
    :unit,
    :permissions,
    :actions,
    :operational_timeline,
    :checked_in_by_name

  def status_label
    I18n.t("frontend.admin.visits.statuses.#{object.status}", default: object.status.to_s.humanize)
  end

  def visit_type_label
    return nil if object.visit_type.blank?

    I18n.t("frontend.admin.visits.visit_types.#{object.visit_type}", default: object.visit_type.to_s.humanize)
  end

  def visitor
    person_summary(object.visitor_person)
  end

  def host
    person_summary(object.host_person)
  end

  def unit
    u = object.unit
    return nil unless u

    { id: u.id, identifier: u.identifier, display_name: u.display_name }
  end

  def permissions
    @permissions ||= begin
      policy = build_policy
      {
        show: policy.show?,
        check_in: policy.check_in?,
        check_out: policy.check_out?,
        restricted_detail: policy.restricted_detail?
      }
    end
  end

  def actions
    permissions.filter_map { |action, allowed| action.to_s if allowed }
  end

  def operational_timeline
    object.visit_status_histories
          .where(event_type: [
            VisitEventTypes::AUTHORIZED,
            VisitEventTypes::CHECKED_IN,
            VisitEventTypes::CHECKED_OUT
          ])
          .map { |entry| Concierge::VisitTimelineEntrySerializer.new(entry).as_json }
  end

  def checked_in_by_name
    object.checked_in_by&.name
  end

  private

  def build_policy
    @instance_options[:policy] || VisitPolicy.new(current_user, object)
  end

  def current_user
    @instance_options[:current_user] || scope
  end

  def person_summary(person)
    return nil unless person

    { id: person.id, display_name: person.display_name }
  end
end
