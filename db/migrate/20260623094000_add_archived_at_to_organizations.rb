class AddArchivedAtToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :archived_at, :datetime
    add_index :organizations, :archived_at
  end
end
