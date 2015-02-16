class AddTripSectionToFlights < ActiveRecord::Migration
  def change
    add_column :flights, :trip_section, :integer
  end
end
