class AddProductionQueryIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :memberships, [ :organization_id, :role ]
    add_index :rsvps, [ :event_id, :status ]
    add_index :attendance_records, [ :event_id, :status ]
    add_index :announcements, [ :organization_id, :audience, :status ], name: "index_announcements_on_organization_audience_status"
    add_index :activity_log_entries, [ :organization_id, :action, :occurred_at ], name: "index_activity_log_entries_on_organization_action_occurred_at"
    add_index :organization_join_links, [ :organization_id, :active, :expires_at ], name: "index_join_links_on_organization_active_expires_at"
  end
end
