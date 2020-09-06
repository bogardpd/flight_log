class AddIndexToUsersName < ActiveRecord::Migration[5.0]
  def self.up
    add_index :users, :name, :unique => true
  end

  def self.down
  end
end
