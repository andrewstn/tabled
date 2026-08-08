class AddSettingsFieldsToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :contact_email, :string
    add_column :organizations, :website_url, :string
    add_column :organizations, :meeting_note, :string
    add_column :organizations, :current_semester_label, :string
  end
end
