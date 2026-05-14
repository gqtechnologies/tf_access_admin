# frozen_string_literal: true

# == Schema Information
#
# Table name: incident_status_histories
#
#  id                   :uuid             not null, primary key
#  from_status          :string
#  metadata             :jsonb            not null
#  reason               :text
#  to_status            :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  changed_by_person_id :uuid
#  incident_id          :uuid             not null
#  organization_id      :uuid             not null
#
# Indexes
#
#  index_incident_status_histories_on_changed_by_person_id     (changed_by_person_id)
#  index_incident_status_histories_on_incident_id              (incident_id)
#  index_incident_status_histories_on_metadata                 (metadata) USING gin
#  index_incident_status_histories_on_org_changed_by_person    (organization_id,changed_by_person_id)
#  index_incident_status_histories_on_org_incident_created_at  (organization_id,incident_id,created_at)
#  index_incident_status_histories_on_organization_id          (organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (changed_by_person_id => people.id)
#  fk_rails_...  (incident_id => incidents.id)
#  fk_rails_...  (organization_id => organizations.id)
#
class IncidentStatusHistory < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :incident
  belongs_to :changed_by_person, class_name: "Person", optional: true
end
