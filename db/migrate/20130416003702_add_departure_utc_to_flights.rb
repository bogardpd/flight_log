class AddDepartureUtcToFlights < ActiveRecord::Migration[5.0]
  def change
    add_column :flights, :departure_utc, :datetime
  end
end
