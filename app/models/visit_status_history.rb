# frozen_string_literal: true

# == Schema Information
#
# Table name: visit_status_histories
#
#  id                   :uuid             not null, primary key
#  from_status          :string
#  metadata             :jsonb            not null
#  reason               :text
#  to_status            :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  changed_by_person_id :uuid
#  organization_id      :uuid             not null
#  visit_id             :uuid             not null
#
# Indexes
#
#  index_visit_status_histories_on_changed_by_person_id           (changed_by_person_id)
#  index_visit_status_histories_on_metadata                       (metadata) USING gin
#  index_visit_status_histories_on_org_visit_created_at           (organization_id,visit_id,created_at)
#  index_visit_status_histories_on_organization_id                (organization_id)
#  index_visit_status_histories_on_organization_id_and_to_status  (organization_id,to_status)
#  index_visit_status_histories_on_visit_id                       (visit_id)
#
# Foreign Keys
#
#  fk_rails_...  (changed_by_person_id => people.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (visit_id => visits.id)
#
class VisitStatusHistory < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :visit
  belongs_to :changed_by_person, class_name: "Person", optional: true

  validates_same_tenant :visit, :changed_by_person
end
