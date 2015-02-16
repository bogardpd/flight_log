class AddIndexToAirportsIataCode < ActiveRecord::Migration
  def change
    add_index :airports, :iata_code, :unique => true
  end
end
