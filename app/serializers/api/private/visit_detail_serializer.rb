# frozen_string_literal: true

# Full visit payload for GET /api/v1/private/units/:unit_id/visits/:id.
# Never exposes the visitor's identity document.
class Api::Private::VisitDetailSerializer < ActiveModel::Serializer
  attributes :id, :status, :effective_status, :scheduled_at, :valid_from, :valid_until,
             :checked_in_at, :checked_out_at, :visitor, :can_cancel, :can_resend,
             :can_authorize, :can_reject

  def effective_status
    object.effective_operational_status
  end

  def visitor
    person = object.visitor_person

    {
      name: person&.display_name,
      email: person&.contact_email.presence,
      phone: person&.try(:contact_phone).presence
    }
  end

  # Same state rule as VisitPolicy#cancel?; the capability is enforced by the
  # controller's unit-level authorization.
  def can_cancel
    object.status.in?([ VisitStatuses::PENDING, VisitStatuses::AUTHORIZED ])
  end

  # Only a pending request can be answered; the capability is enforced by the
  # controller's unit-level authorization.
  def can_authorize
    object.status == VisitStatuses::PENDING
  end

  def can_reject
    object.status == VisitStatuses::PENDING
  end

  def can_resend
    Visits::ResendVisitorInvitation.resendable?(object)
  end
end
