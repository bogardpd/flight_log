class AddSlugToAirportsAndAircraftFamilies < ActiveRecord::Migration[5.2]
  def change
    add_column :airports, :slug, :string
    add_index :airports, :slug, unique: true
    add_column :aircraft_families, :slug, :string
    add_index :aircraft_families, :slug, unique: true
  end
end
