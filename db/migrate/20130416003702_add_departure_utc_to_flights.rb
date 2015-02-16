class AddDepartureUtcToFlights < ActiveRecord::Migration
  def change
    add_column :flights, :departure_utc, :datetime
  end
end
