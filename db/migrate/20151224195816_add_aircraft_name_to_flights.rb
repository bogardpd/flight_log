class AddAircraftNameToFlights < ActiveRecord::Migration[5.0]
  def change
    add_column :flights, :aircraft_name, :string
  end
end
