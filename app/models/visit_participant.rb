# frozen_string_literal: true

# == Schema Information
#
# Table name: visit_participants
#
#  id                       :uuid             not null, primary key
#  checked_in_at            :datetime
#  checked_out_at           :datetime
#  document_snapshot_digest :string
#  metadata                 :jsonb            not null
#  name_snapshot            :string
#  notes                    :text
#  status                   :string           default("pending"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  organization_id          :uuid             not null
#  person_id                :uuid
#  validated_by_id          :uuid
#  visit_id                 :uuid             not null
#  visitor_profile_id       :uuid
#
# Indexes
#
#  idx_on_organization_id_visit_id_status_d1b6982805          (organization_id,visit_id,status)
#  idx_on_organization_id_visitor_profile_id_0adf418fb3       (organization_id,visitor_profile_id)
#  index_visit_participants_on_metadata                       (metadata) USING gin
#  index_visit_participants_on_organization_id                (organization_id)
#  index_visit_participants_on_organization_id_and_person_id  (organization_id,person_id)
#  index_visit_participants_on_person_id                      (person_id)
#  index_visit_participants_on_validated_by_id                (validated_by_id)
#  index_visit_participants_on_visit_id                       (visit_id)
#  index_visit_participants_on_visitor_profile_id             (visitor_profile_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (validated_by_id => users.id)
#  fk_rails_...  (visit_id => visits.id)
#  fk_rails_...  (visitor_profile_id => visitor_profiles.id)
#
class VisitParticipant < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :visit
  belongs_to :visitor_profile, optional: true
  belongs_to :person, optional: true
  belongs_to :validated_by, class_name: "User", optional: true
end
