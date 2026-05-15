# frozen_string_literal: true

# == Schema Information
#
# Table name: visit_recurrences
#
#  id              :uuid             not null, primary key
#  byday           :string
#  bymonth         :string
#  bymonthday      :string
#  count           :integer
#  dtstart         :datetime         not null
#  freq            :string           not null
#  interval        :integer          default(1), not null
#  metadata        :jsonb            not null
#  timezone        :string           default("America/Santiago"), not null
#  until_at        :datetime
#  wkst            :string           default("MO"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :uuid             not null
#  visit_id        :uuid             not null
#
# Indexes
#
#  index_visit_recurrences_on_metadata         (metadata) USING gin
#  index_visit_recurrences_on_org_dtstart      (organization_id,dtstart)
#  index_visit_recurrences_on_org_freq         (organization_id,freq)
#  index_visit_recurrences_on_organization_id  (organization_id)
#  index_visit_recurrences_on_visit_id         (visit_id)
#  index_visit_recurrences_unique_per_visit    (organization_id,visit_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (visit_id => visits.id)
#
class VisitRecurrence < ApplicationRecord
  acts_as_tenant :organization

  FREQ_DAILY   = "DAILY"
  FREQ_WEEKLY  = "WEEKLY"
  FREQ_MONTHLY = "MONTHLY"
  FREQ_YEARLY  = "YEARLY"

  FREQUENCIES = [ FREQ_DAILY, FREQ_WEEKLY, FREQ_MONTHLY, FREQ_YEARLY ].freeze

  WEEKDAYS = %w[MO TU WE TH FR SA SU].freeze

  belongs_to :organization
  belongs_to :visit

  validates :freq,     presence: true, inclusion: { in: FREQUENCIES }
  validates :interval, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :count,    numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :dtstart,  presence: true
  validates :wkst,     inclusion: { in: WEEKDAYS }, allow_nil: true
  validates :visit_id, uniqueness: { scope: :organization_id }
  validate  :until_or_count_only
  validate  :until_after_dtstart
  validate  :byday_format
  validate  :bymonthday_format
  validate  :bymonth_format
  validate  :visit_belongs_to_same_organization

  # Returns the RFC5545 RRULE string equivalent (without DTSTART line).
  def to_rrule
    parts = [ "FREQ=#{freq}" ]
    parts << "INTERVAL=#{interval}" if interval && interval != 1
    parts << "COUNT=#{count}" if count.present?
    parts << "UNTIL=#{until_at.utc.strftime('%Y%m%dT%H%M%SZ')}" if until_at.present?
    parts << "BYDAY=#{byday}" if byday.present?
    parts << "BYMONTHDAY=#{bymonthday}" if bymonthday.present?
    parts << "BYMONTH=#{bymonth}" if bymonth.present?
    parts << "WKST=#{wkst}" if wkst.present? && wkst != "MO"
    parts.join(";")
  end

  private

  def until_or_count_only
    return if until_at.blank? || count.blank?

    errors.add(:base, :until_or_count_exclusive)
  end

  def until_after_dtstart
    return if until_at.blank? || dtstart.blank?
    return if until_at >= dtstart

    errors.add(:until_at, :must_be_after_dtstart)
  end

  def byday_format
    return if byday.blank?
    return if byday.split(",").map(&:strip).all? { |d| WEEKDAYS.include?(d) }

    errors.add(:byday, :invalid_weekday_list)
  end

  def bymonthday_format
    return if bymonthday.blank?
    days = bymonthday.split(",").map(&:strip)
    return if days.all? { |d| d.match?(/\A-?\d+\z/) && d.to_i.between?(-31, 31) && d.to_i != 0 }

    errors.add(:bymonthday, :invalid_monthday_list)
  end

  def bymonth_format
    return if bymonth.blank?
    months = bymonth.split(",").map(&:strip)
    return if months.all? { |m| m.match?(/\A\d+\z/) && m.to_i.between?(1, 12) }

    errors.add(:bymonth, :invalid_month_list)
  end

  def visit_belongs_to_same_organization
    return if visit.blank? || organization_id.blank?
    return if visit.organization_id == organization_id

    errors.add(:visit, :different_tenant)
  end
end
