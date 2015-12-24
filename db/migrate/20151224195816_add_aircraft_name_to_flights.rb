class AddAircraftNameToFlights < ActiveRecord::Migration
  def change
    add_column :flights, :aircraft_name, :string
  end
end
