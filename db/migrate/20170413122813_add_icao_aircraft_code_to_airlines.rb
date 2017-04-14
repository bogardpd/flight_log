class AddIcaoAircraftCodeToAirlines < ActiveRecord::Migration[5.0]
  def change
    add_column :airlines, :icao_airline_code, :string
    add_index :airlines, :iata_airline_code
    add_index :airlines, :icao_airline_code
  end
end
