class AddTripSectionToFlights < ActiveRecord::Migration[5.0]
  def change
    add_column :flights, :trip_section, :integer
  end
end
