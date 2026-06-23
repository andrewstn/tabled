class CreateAnnouncementDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :announcement_deliveries do |t|
      t.references :announcement, null: false, foreign_key: true
      t.references :membership, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :email, null: false
      t.string :status, null: false
      t.string :skipped_reason
      t.datetime :sent_at

      t.timestamps
    end

    add_index :announcement_deliveries, [ :announcement_id, :membership_id ], unique: true
    add_check_constraint :announcement_deliveries, "status IN ('sent', 'skipped')", name: "announcement_deliveries_status_check"
  end
end
