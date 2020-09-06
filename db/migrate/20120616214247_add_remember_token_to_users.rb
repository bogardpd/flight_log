class AddRememberTokenToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :remember_token, :string
    add_index :users, :remember_token
  end
end
