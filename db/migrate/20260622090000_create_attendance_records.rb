class CreateAttendanceRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_records do |t|
      t.references :event, null: false, foreign_key: true
      t.references :membership, null: false, foreign_key: true
      t.references :marked_by, foreign_key: { to_table: :users }
      t.string :status, null: false
      t.datetime :checked_in_at
      t.text :note

      t.timestamps
    end

    add_index :attendance_records, %i[event_id membership_id], unique: true
    add_index :attendance_records, %i[membership_id created_at]
    add_check_constraint :attendance_records,
      "status IN ('present', 'late', 'excused', 'absent')",
      name: "attendance_records_status_check"
  end
end
