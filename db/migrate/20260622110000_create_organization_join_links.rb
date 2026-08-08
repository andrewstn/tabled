class CreateOrganizationJoinLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_join_links do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :label, null: false
      t.string :role, null: false, default: "member"
      t.boolean :active, null: false, default: true
      t.datetime :expires_at
      t.integer :max_uses
      t.integer :uses_count, null: false, default: 0

      t.timestamps
    end

    add_index :organization_join_links, [ :organization_id, :active ]
    add_check_constraint :organization_join_links, "max_uses IS NULL OR max_uses > 0", name: "join_links_positive_max_uses"
    add_check_constraint :organization_join_links, "uses_count >= 0", name: "join_links_nonnegative_uses_count"
  end
end
