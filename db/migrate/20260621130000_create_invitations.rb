class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :role, null: false
      t.string :token_digest, null: false
      t.datetime :accepted_at
      t.datetime :revoked_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :invitations, :token_digest, unique: true
    add_index :invitations, "organization_id, lower(email)",
      unique: true,
      where: "accepted_at IS NULL AND revoked_at IS NULL",
      name: "index_invitations_on_pending_organization_email"
    add_check_constraint :invitations,
      "role IN ('owner', 'officer', 'coordinator', 'member')",
      name: "invitations_role_check"
  end
end
