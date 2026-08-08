class CreateActivityLogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_log_entries do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :subject_type
      t.bigint :subject_id
      t.string :summary, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :activity_log_entries, [ :organization_id, :occurred_at ]
    add_index :activity_log_entries, :action
    add_index :activity_log_entries, [ :subject_type, :subject_id ]
  end
end
