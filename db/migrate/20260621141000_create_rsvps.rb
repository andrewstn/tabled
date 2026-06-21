class CreateRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :rsvps do |t|
      t.references :event, null: false, foreign_key: true
      t.references :membership, null: false, foreign_key: true
      t.string :status, null: false
      t.text :note

      t.timestamps
    end

    add_index :rsvps, %i[event_id membership_id], unique: true
    add_check_constraint :rsvps,
      "status IN ('attending', 'maybe', 'not_attending')",
      name: "rsvps_status_check"
  end
end
