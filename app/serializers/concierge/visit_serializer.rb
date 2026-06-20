# frozen_string_literal: true

# Minimal operational serializer for Visit, used in concierge endpoints.
# Exposes only the fields needed for access-control operations.
# Section 7 (7.3, 7.6, 7.7) will extend this with operational list/detail/summary payloads.
class Concierge::VisitSerializer < ActiveModel::Serializer
  attributes :id,
    :status,
    :visit_type,
    :scheduled_at,
    :valid_from,
    :valid_until,
    :checked_in_at,
    :checked_out_at,
    :residential_property_id,
    :unit_id,
    :visitor_person_id,
    :host_person_id,
    :permissions

  def permissions
    policy = @instance_options[:policy] || VisitPolicy.new(current_user, object)
    {
      show: policy.show?,
      check_in: policy.check_in?,
      check_out: policy.check_out?,
      restricted_detail: policy.restricted_detail?
    }
  end

  private

  def current_user
    @instance_options[:current_user] || scope
  end
end
