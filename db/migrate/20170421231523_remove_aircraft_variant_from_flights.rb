class RemoveAircraftVariantFromFlights < ActiveRecord::Migration[5.0]
  def change
    remove_column :flights, :aircraft_variant, :string
  end
end
