class RemoveOldAircraftFamilyFromFlights < ActiveRecord::Migration
  def change
    remove_column :flights, :old_aircraft_family, :string
  end
end
