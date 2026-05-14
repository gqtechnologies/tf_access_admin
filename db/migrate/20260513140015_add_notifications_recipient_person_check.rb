# frozen_string_literal: true

class AddNotificationsRecipientPersonCheck < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :notifications, "recipient_person_id IS NOT NULL",
                         name: "notifications_recipient_person_required"
  end
end
