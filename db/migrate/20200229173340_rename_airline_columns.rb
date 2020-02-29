class RenameAirlineColumns < ActiveRecord::Migration[6.0]
  def change
    rename_column :airlines, :airline_name, :name
    rename_column :airlines, :iata_airline_code, :iata_code
    rename_column :airlines, :icao_airline_code, :icao_code
  end
end
