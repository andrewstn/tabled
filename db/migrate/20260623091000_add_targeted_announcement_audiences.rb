class AddTargetedAnnouncementAudiences < ActiveRecord::Migration[8.1]
  def change
    add_reference :announcements, :target_event, foreign_key: { to_table: :events }

    reversible do |dir|
      dir.up do
        execute "ALTER TABLE announcements DROP CONSTRAINT announcements_audience_check"
        execute <<~SQL.squish
          ALTER TABLE announcements
          ADD CONSTRAINT announcements_audience_check
          CHECK (audience IN ('all_members', 'officers', 'event_rsvps', 'event_attendees'))
        SQL
      end

      dir.down do
        execute "ALTER TABLE announcements DROP CONSTRAINT announcements_audience_check"
        execute <<~SQL.squish
          ALTER TABLE announcements
          ADD CONSTRAINT announcements_audience_check
          CHECK (audience IN ('all_members', 'officers'))
        SQL
      end
    end
  end
end
