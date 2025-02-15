class AddFaFlightIdToFlights < ActiveRecord::Migration[7.2]
  def change
    add_column :flights, :fa_flight_id, :string
  end
end
