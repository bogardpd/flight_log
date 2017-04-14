class RemoveIndexFromAirlinesIcao < ActiveRecord::Migration[5.0]
  def change
    remove_index :airlines, column: [:icao_airline_code]
  end
end
