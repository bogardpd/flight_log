class AddAircraftFamilyIdToFlights < ActiveRecord::Migration
  def change
    add_column :flights, :aircraft_family_id, :integer
  end
end
