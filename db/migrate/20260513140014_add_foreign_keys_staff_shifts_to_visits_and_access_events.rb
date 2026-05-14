# frozen_string_literal: true

class AddForeignKeysStaffShiftsToVisitsAndAccessEvents < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :visits, :staff_shifts, column: :staff_shift_id, validate: true
    add_foreign_key :access_events, :staff_shifts, column: :staff_shift_id, validate: true
  end
end
