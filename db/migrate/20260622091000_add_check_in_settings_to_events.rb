class AddCheckInSettingsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :check_in_opens_at, :datetime
    add_column :events, :check_in_closes_at, :datetime
    add_column :events, :check_in_code_digest, :string
    add_index :events, %i[organization_id check_in_opens_at check_in_closes_at], name: "index_events_on_organization_and_check_in_window"
    add_check_constraint :events,
      "check_in_opens_at IS NULL OR check_in_closes_at IS NULL OR check_in_closes_at > check_in_opens_at",
      name: "events_check_in_window_order"
  end
end
