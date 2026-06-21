class CreateOrganizationsAndMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end
    add_index :organizations, :slug, unique: true

    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end
    add_index :memberships, %i[user_id organization_id], unique: true
    add_check_constraint :memberships,
      "role IN ('owner', 'officer', 'coordinator', 'member')",
      name: "memberships_role_check"
  end
end
