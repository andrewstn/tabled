class AddCommunicationPreferencesToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :announcement_emails_enabled, :boolean, null: false, default: true
    add_column :memberships, :event_reminder_emails_enabled, :boolean, null: false, default: true
    add_column :memberships, :recruitment_emails_enabled, :boolean, null: false, default: true
  end
end
