class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :body, null: false
      t.string :audience, null: false
      t.string :status, null: false, default: "draft"
      t.boolean :pinned, null: false, default: false
      t.datetime :published_at
      t.datetime :emailed_at

      t.timestamps
    end

    add_index :announcements, %i[organization_id status pinned published_at], name: "index_announcements_for_bulletin"
    add_check_constraint :announcements,
      "audience IN ('all_members', 'officers')",
      name: "announcements_audience_check"
    add_check_constraint :announcements,
      "status IN ('draft', 'published')",
      name: "announcements_status_check"
  end
end
