class AddDemoAccountToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :demo_account, :boolean, null: false, default: false
    add_index :users, :demo_account
  end
end
