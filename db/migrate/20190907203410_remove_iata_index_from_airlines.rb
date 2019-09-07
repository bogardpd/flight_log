class RemoveIataIndexFromAirlines < ActiveRecord::Migration[5.2]
  def change
    remove_index :airlines, name: "index_airlines_on_iata_airline_code"
  end
end
