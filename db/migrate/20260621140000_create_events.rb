class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :location
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.integer :capacity
      t.datetime :rsvp_deadline

      t.timestamps
    end

    add_index :events, %i[organization_id starts_at]
    add_check_constraint :events, "ends_at IS NULL OR ends_at > starts_at",
      name: "events_end_after_start"
    add_check_constraint :events, "capacity IS NULL OR capacity > 0",
      name: "events_positive_capacity"
    add_check_constraint :events, "rsvp_deadline IS NULL OR rsvp_deadline <= starts_at",
      name: "events_deadline_before_start"
  end
end
