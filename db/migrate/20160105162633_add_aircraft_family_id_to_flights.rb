class AddAircraftFamilyIdToFlights < ActiveRecord::Migration[5.0]
  def change
    add_column :flights, :aircraft_family_id, :integer
  end
end
