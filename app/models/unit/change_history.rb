# frozen_string_literal: true

class Unit::ChangeHistory
  PREVIEW_LIMIT = 10

  ENTRY = Struct.new(:id, :occurred_at, :description, :actor_name, :tone, keyword_init: true)

  def self.for(unit, limit: PREVIEW_LIMIT)
    new(unit, limit: limit).entries
  end

  def initialize(unit, limit: PREVIEW_LIMIT)
    @unit = unit
    @limit = limit
  end

  def entries
    audits.map { |audit| build_entry(audit) }.compact.map(&:to_h)
  end

  private

  def audits
    @audits ||= TenantAudit
      .where(organization_id: @unit.organization_id)
      .where(
        <<~SQL.squish,
          (auditable_type = 'Unit' AND auditable_id = :unit_id)
          OR (associated_type = 'Unit' AND associated_id = :unit_id)
        SQL
        unit_id: @unit.id
      )
      .order(created_at: :desc)
      .limit(@limit)
      .includes(:user)
      .to_a
  end

  def build_entry(audit)
    context = preload_context
    description = description_for(audit, context)
    return if description.blank?

    ENTRY.new(
      id: audit.id,
      occurred_at: audit.created_at.iso8601,
      description: description,
      actor_name: actor_name_for(audit),
      tone: tone_for(audit)
    )
  end

  def preload_context
    @preload_context ||= begin
      person_ids = Set.new
      section_ids = Set.new
      ownership_ids = []
      occupancy_ids = []

      audits.each do |audit|
        case audit.auditable_type
        when "UnitOwnership"
          ownership_ids << audit.auditable_id
          collect_ids_from_changes(audit.audited_changes, :person_id, person_ids)
        when "UnitOccupancy"
          occupancy_ids << audit.auditable_id
          collect_ids_from_changes(audit.audited_changes, :person_id, person_ids)
        when "Unit"
          collect_ids_from_changes(audit.audited_changes, :property_section_id, section_ids)
        end
      end

      ownerships = UnitOwnership.with_deleted
        .where(id: ownership_ids)
        .includes(:person)
        .index_by(&:id)
      ownerships.each_value { |ownership| person_ids << ownership.person_id if ownership.person_id.present? }

      occupancies = UnitOccupancy.with_deleted
        .where(id: occupancy_ids)
        .includes(:person)
        .index_by(&:id)
      occupancies.each_value { |occupancy| person_ids << occupancy.person_id if occupancy.person_id.present? }

      {
        people: Person.with_deleted.where(id: person_ids.to_a).index_by(&:id),
        sections: PropertySection.where(id: section_ids.to_a).index_by(&:id),
        ownerships: ownerships,
        occupancies: occupancies
      }
    end
  end

  def collect_ids_from_changes(changes, attribute, bucket)
    return unless changes.is_a?(Hash)

    Array(changes[attribute.to_s] || changes[attribute.to_sym]).each do |value|
      bucket << value if value.present?
    end
  end

  def description_for(audit, context)
    case audit.auditable_type
    when "Unit"
      unit_description(audit, context)
    when "UnitOwnership"
      ownership_description(audit, context)
    when "UnitOccupancy"
      occupancy_description(audit, context)
    end
  end

  def unit_description(audit, context)
    actor = actor_name_for(audit)

    case audit.action
    when "create"
      t("events.unit_created")
    when "update"
      changes = audit.audited_changes.to_h
      if changes.key?("status") || changes.key?(:status)
        _, to = Array(changes["status"] || changes[:status])
        return t("events.unit_status_changed", actor:, to: format_unit_status(to))
      end

      formatted_changes = format_unit_changes(changes, context)
      return t("events.unit_updated", actor:, changes: formatted_changes) if formatted_changes.present?

      t("events.generic_update", actor:)
    when "destroy"
      t("events.unit_destroyed", actor:)
    end
  end

  def ownership_description(audit, context)
    actor = actor_name_for(audit)
    ownership = context[:ownerships][audit.auditable_id]
    person = person_for(audit, ownership, context)

    case audit.action
    when "create"
      percentage = ownership&.ownership_percentage || audit.audited_changes.to_h.dig("ownership_percentage", 1)
      t(
        "events.ownership_created",
        actor:,
        person:,
        percentage: format_percentage(percentage)
      )
    when "update"
      changes = audit.audited_changes.to_h

      if changes.key?("ownership_percentage") || changes.key?(:ownership_percentage)
        from, to = Array(changes["ownership_percentage"] || changes[:ownership_percentage])
        return t(
          "events.ownership_percentage_changed",
          actor:,
          person:,
          from: format_percentage(from),
          to: format_percentage(to)
        )
      end

      if changes.key?("status") || changes.key?(:status)
        _, to = Array(changes["status"] || changes[:status])
        return t("events.ownership_status_changed", actor:, person:, to: format_ownership_status(to))
      end

      t("events.ownership_updated", actor:, person:)
    when "destroy"
      t("events.ownership_removed", actor:, person:)
    end
  end

  def occupancy_description(audit, context)
    actor = actor_name_for(audit)
    occupancy = context[:occupancies][audit.auditable_id]
    person = person_for_occupancy(audit, occupancy, context)

    case audit.action
    when "create"
      occupancy_type = occupancy&.occupancy_type || Array(audit.audited_changes.to_h["occupancy_type"]).last
      t(
        "events.occupancy_created",
        actor:,
        person:,
        type: format_occupancy_type(occupancy_type)
      )
    when "update"
      changes = audit.audited_changes.to_h

      if changes.key?("occupancy_type") || changes.key?(:occupancy_type)
        _, to = Array(changes["occupancy_type"] || changes[:occupancy_type])
        return t(
          "events.occupancy_type_changed",
          actor:,
          person:,
          to: format_occupancy_type(to)
        )
      end

      if changes.key?("status") || changes.key?(:status)
        _, to = Array(changes["status"] || changes[:status])
        return t("events.occupancy_status_changed", actor:, person:, to: format_occupancy_status(to))
      end

      if changes.key?("can_authorize_visits") || changes.key?(:can_authorize_visits)
        _, to = Array(changes["can_authorize_visits"] || changes[:can_authorize_visits])
        return t(
          "events.occupancy_authorization_changed",
          actor:,
          person:,
          to: format_boolean(to)
        )
      end

      t("events.occupancy_updated", actor:, person:)
    when "destroy"
      t("events.occupancy_removed", actor:, person:)
    end
  end

  def format_unit_changes(changes, context)
    changes.filter_map do |attribute, values|
      from, to = Array(values)
      next if from == to

      label = t("attributes.#{attribute}", default: attribute.to_s.humanize)
      formatted_from = format_unit_attribute(attribute, from, context)
      formatted_to = format_unit_attribute(attribute, to, context)
      t("events.change_pair", label:, from: formatted_from, to: formatted_to)
    end.join(", ")
  end

  def format_unit_attribute(attribute, value, context)
    return t("events.blank_value") if value.blank?

    case attribute.to_s
    when "status"
      format_unit_status([ nil, value ].last)
    when "unit_type"
      t_unit_type(value)
    when "area_m2"
      t("events.area_value", value: value)
    when "property_section_id"
      context[:sections][value]&.name || value
    else
      value.to_s
    end
  end

  def format_unit_status(value_or_pair)
    status = value_or_pair.is_a?(Array) ? value_or_pair.last : value_or_pair
    t_unit_status(status)
  end

  def format_ownership_status(status)
    t("ownership_statuses.#{status}", default: status.to_s.humanize)
  end

  def format_occupancy_status(status)
    t("occupancy_statuses.#{status}", default: status.to_s.humanize)
  end

  def format_occupancy_type(occupancy_type)
    return t("events.blank_value") if occupancy_type.blank?

    I18n.t(
      "frontend.admin.unit_occupancies.occupancy_types.#{occupancy_type}",
      default: occupancy_type.to_s.humanize
    )
  end

  def format_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value) ? t("events.boolean_yes") : t("events.boolean_no")
  end

  def format_percentage(value)
    return "—" if value.blank?

    number = value.to_d
    formatted = number.frac.zero? ? number.to_i.to_s : number.round(1).to_s
    "#{formatted}%"
  end

  def person_for(audit, ownership, context)
    changes = audit.audited_changes.to_h
    person_id = ownership&.person_id || Array(changes["person_id"] || changes[:person_id]).last
    context[:people][person_id]&.display_name || t("events.unknown_person")
  end

  def person_for_occupancy(audit, occupancy, context)
    changes = audit.audited_changes.to_h
    person_id = occupancy&.person_id || Array(changes["person_id"] || changes[:person_id]).last
    context[:people][person_id]&.display_name || t("events.unknown_occupant")
  end

  def actor_name_for(audit)
    audit.user&.name.presence || audit.username.presence || t("actor_fallback")
  end

  def tone_for(audit)
    return "success" if audit.action == "create"
    return "warning" if audit.action == "destroy" || status_changed?(audit)

    "neutral"
  end

  def status_changed?(audit)
    changes = audit.audited_changes.to_h
    changes.key?("status") || changes.key?(:status)
  end

  def t_unit_status(status)
    I18n.t(
      "frontend.admin.residential_properties.structure.bulk_import.preview.unit_statuses.#{status}",
      default: status.to_s.humanize
    )
  end

  def t_unit_type(unit_type)
    I18n.t(
      "frontend.admin.residential_properties.structure.bulk_import.preview.unit_types.#{unit_type}",
      default: unit_type.to_s.humanize
    )
  end

  def t(key, **options)
    I18n.t("frontend.admin.units.show.change_history.#{key}", **options)
  end
end
