class AddIcaoAndParentToAircraftFamilies < ActiveRecord::Migration[5.0]
  def change
    add_column :aircraft_families, :icao_aircraft_code, :string
    add_column :aircraft_families, :parent_id, :integer
  end
end
