class RemoveOldAircraftFamilyFromFlights < ActiveRecord::Migration[5.0]
  def change
    remove_column :flights, :old_aircraft_family, :string
  end
end
