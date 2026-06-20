# frozen_string_literal: true

# Minimal administrative serializer for Visit.
# Exposes core fields and backend-calculated `permissions` per visit.
# Section 7 (7.4, 7.5, 7.9) will extend this with full list/detail payloads.
class Admin::VisitSerializer < ActiveModel::Serializer
  attributes :id,
    :status,
    :visit_type,
    :scheduled_at,
    :valid_from,
    :valid_until,
    :authorized_at,
    :checked_in_at,
    :checked_out_at,
    :notes,
    :created_at,
    :updated_at,
    :organization_id,
    :residential_property_id,
    :property_section_id,
    :unit_id,
    :visitor_person_id,
    :host_person_id,
    :created_by_id,
    :authorized_by_id,
    :checked_in_by_id,
    :checked_out_by_id,
    :permissions

  def permissions
    policy = @instance_options[:policy] || VisitPolicy.new(current_user, object)
    {
      show: policy.show?,
      create: policy.create?,
      update: policy.update?,
      authorize: policy.authorize?,
      cancel: policy.cancel?,
      check_in: policy.check_in?,
      check_out: policy.check_out?,
      full_detail: policy.full_detail?,
      restricted_detail: policy.restricted_detail?
    }
  end

  private

  def current_user
    @instance_options[:current_user] || scope
  end
end
