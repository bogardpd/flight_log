class ChangeAircraftFamilyToOld < ActiveRecord::Migration[5.0]
  def change
    rename_column :flights, :aircraft_family, :old_aircraft_family
  end
end
