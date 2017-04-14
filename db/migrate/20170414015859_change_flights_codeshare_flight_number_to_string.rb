class ChangeFlightsCodeshareFlightNumberToString < ActiveRecord::Migration[5.0]
  def change
    change_column :flights, :codeshare_flight_number, :string
  end
end
