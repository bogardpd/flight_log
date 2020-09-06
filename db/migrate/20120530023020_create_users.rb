class CreateUsers < ActiveRecord::Migration[5.0]
  def self.up
    create_table :users do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
