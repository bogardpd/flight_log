class RemoveIataCodeIndexFromAirports < ActiveRecord::Migration[5.2]
  def change
    remove_index :airports, name: "index_airports_on_iata_code"
  end
end
