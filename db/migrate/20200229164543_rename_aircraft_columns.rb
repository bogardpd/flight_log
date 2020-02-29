class RenameAircraftColumns < ActiveRecord::Migration[6.0]
  def change
    rename_column :aircraft_families, :family_name, :name
    rename_column :aircraft_families, :iata_aircraft_code, :iata_code
    rename_column :aircraft_families, :icao_aircraft_code, :icao_code    
  end
end
