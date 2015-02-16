class AddIndexToUsersName < ActiveRecord::Migration
  def self.up
    add_index :users, :name, :unique => true
  end

  def self.down
  end
end
