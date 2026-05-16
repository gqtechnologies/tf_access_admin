# frozen_string_literal: true

# == Schema Information
#
# Table name: common_area_reservation_status_histories
#
#  id                         :uuid             not null, primary key
#  from_status                :string
#  metadata                   :jsonb            not null
#  reason                     :text
#  to_status                  :string           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  changed_by_person_id       :uuid
#  common_area_reservation_id :uuid             not null
#  organization_id            :uuid             not null
#
# Indexes
#
#  idx_c_area_res_status_histories_on_org_changed_by           (organization_id,changed_by_person_id)
#  idx_c_area_res_status_histories_on_org_res_created          (organization_id,common_area_reservation_id,created_at)
#  idx_on_changed_by_person_id_882d57421f                      (changed_by_person_id)
#  idx_on_common_area_reservation_id_f6c327d821                (common_area_reservation_id)
#  idx_on_organization_id_e7e8651341                           (organization_id)
#  index_common_area_reservation_status_histories_on_metadata  (metadata) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (changed_by_person_id => people.id)
#  fk_rails_...  (common_area_reservation_id => common_area_reservations.id)
#  fk_rails_...  (organization_id => organizations.id)
#
class CommonAreaReservationStatusHistory < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :common_area_reservation
  belongs_to :changed_by_person, class_name: "Person", optional: true

  validates_same_tenant :common_area_reservation, :changed_by_person
end
