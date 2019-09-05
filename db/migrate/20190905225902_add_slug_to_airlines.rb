class AddSlugToAirlines < ActiveRecord::Migration[5.2]
  def change
    add_column :airlines, :slug, :string
    add_index :airlines, :slug, unique: true
  end
end
