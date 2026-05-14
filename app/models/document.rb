# frozen_string_literal: true

# == Schema Information
#
# Table name: documents
#
#  id                    :uuid             not null, primary key
#  category              :string           not null
#  deleted_at            :datetime
#  description           :text
#  documentable_type     :string           not null
#  expires_at            :datetime
#  metadata              :jsonb            not null
#  sensitive             :boolean          default(FALSE), not null
#  status                :string           default("pending"), not null
#  title                 :string           not null
#  visibility            :string           default("private"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  documentable_id       :bigint           not null
#  organization_id       :uuid             not null
#  uploaded_by_person_id :uuid
#
# Indexes
#
#  index_documents_on_deleted_at                     (deleted_at)
#  index_documents_on_metadata                       (metadata) USING gin
#  index_documents_on_org_documentable               (organization_id,documentable_type,documentable_id)
#  index_documents_on_org_status_expires_at          (organization_id,status,expires_at)
#  index_documents_on_org_uploaded_by_person         (organization_id,uploaded_by_person_id)
#  index_documents_on_organization_id                (organization_id)
#  index_documents_on_organization_id_and_category   (organization_id,category)
#  index_documents_on_organization_id_and_sensitive  (organization_id,sensitive)
#  index_documents_on_uploaded_by_person_id          (uploaded_by_person_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (uploaded_by_person_id => people.id)
#
class Document < ApplicationRecord
  acts_as_paranoid
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :uploaded_by_person, class_name: "Person", optional: true
  belongs_to :documentable, polymorphic: true

  has_one_attached :file
end
