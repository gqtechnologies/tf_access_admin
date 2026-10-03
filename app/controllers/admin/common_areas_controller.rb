# frozen_string_literal: true

# Configuration of a property's common areas: name, type, capacity, whether
# reservations need approval, active/inactive, and the reservation rules the
# resident flow enforces (opening hours, max duration, advance notice,
# monthly limit, notes).
class Admin::CommonAreasController < AdminController
  include ManagedPropertyContext

  CAPABILITY = Authorization::Capabilities::MANAGE_COMMON_AREAS
  INT_RULES = [
    CommonAreaRule::RULE_MAX_DURATION_MINUTES,
    CommonAreaRule::RULE_MIN_ADVANCE_HOURS,
    CommonAreaRule::RULE_MAX_RESERVATIONS_MONTH
  ].freeze
  TEXT_RULES = [ CommonAreaRule::RULE_OPENS_AT, CommonAreaRule::RULE_CLOSES_AT, CommonAreaRule::RULE_NOTES ].freeze
  HHMM = /\A([01]\d|2[0-3]):[0-5]\d\z/

  def index
    authorize CommonArea

    property = active_managed_property(CAPABILITY)
    areas = property ? policy_scope(CommonArea).where(residential_property_id: property.id).includes(:common_area_rules).order(:name) : []

    render inertia: "admin/common_areas/index", props: {
      common_areas: areas.map { |area| serialize(area) },
      properties: managed_properties_for(CAPABILITY).map { |p| property_summary(p) },
      active_property: property_summary(property),
      area_types: CommonAreaTypes::ALL
    }
  end

  def create
    property = active_managed_property(CAPABILITY)
    return redirect_with_errors({ base: [ t("frontend.admin.common_areas.errors.no_property") ] }) unless property

    area = CommonArea.new(organization: Current.organization, residential_property: property, status: CommonArea::STATUS_ACTIVE)
    authorize area
    save(area)
  end

  def update
    area = policy_scope(CommonArea).find(params[:id])
    authorize area
    save(area)
  rescue ActiveRecord::RecordNotFound
    redirect_with_errors({ base: [ t("frontend.admin.common_areas.errors.not_found") ] })
  end

  private

  def save(area)
    rules_error = invalid_rules_error
    return redirect_with_errors({ rules: [ rules_error ] }, property_id: area.residential_property_id) if rules_error

    ActiveRecord::Base.transaction do
      area.assign_attributes(area_params)
      area.save!
      sync_rules(area)
    end

    redirect_to admin_common_areas_path(property_id: area.residential_property_id)
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_errors(serialize_inertia_errors(e.record), property_id: area.residential_property_id)
  end

  def rule_params
    params.fetch(:common_area, {}).fetch(:rules, {}).permit(*(INT_RULES + TEXT_RULES)).to_h
  end

  def invalid_rules_error
    rules = rule_params
    bad_int = INT_RULES.any? { |key| rules[key].present? && rules[key].to_s !~ /\A\d+\z/ }
    bad_hour = [ CommonAreaRule::RULE_OPENS_AT, CommonAreaRule::RULE_CLOSES_AT ].any? { |key| rules[key].present? && rules[key] !~ HHMM }
    opens = rules[CommonAreaRule::RULE_OPENS_AT].presence
    closes = rules[CommonAreaRule::RULE_CLOSES_AT].presence
    reversed = opens && closes && !bad_hour && opens >= closes

    t("frontend.admin.common_areas.errors.invalid_rules") if bad_int || bad_hour || reversed
  end

  # Blank values remove the rule; the rest are created or updated.
  def sync_rules(area)
    rule_params.each do |key, raw|
      existing = area.common_area_rules.find_by(rule_type: key)
      value = raw.to_s.strip

      if value.blank?
        existing&.destroy!
        next
      end

      rule = existing || area.common_area_rules.build(organization: area.organization, rule_type: key)
      if INT_RULES.include?(key)
        rule.assign_attributes(value_int: value.to_i, value_text: nil)
      else
        rule.assign_attributes(value_text: value, value_int: nil)
      end
      rule.save!
    end
  end

  def area_params
    params.fetch(:common_area, {}).permit(:name, :area_type, :capacity, :requires_approval, :status)
  end

  def serialize(area)
    {
      id: area.id,
      name: area.name,
      area_type: area.area_type,
      capacity: area.capacity,
      requires_approval: area.requires_approval?,
      status: area.status,
      rules: area.rules,
      upcoming_count: area.common_area_reservations.holding_slot.upcoming.count
    }
  end

  def redirect_with_errors(errors, property_id: params[:property_id])
    redirect_to admin_common_areas_path({ property_id: property_id }.compact), inertia: { errors: errors }
  end
end
