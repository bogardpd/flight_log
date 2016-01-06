class ChangeAircraftFamilyToOld < ActiveRecord::Migration
  def change
    rename_column :flights, :aircraft_family, :old_aircraft_family
  end
end
