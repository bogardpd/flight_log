class CreateAircraftFamilies < ActiveRecord::Migration[5.0]
  def change
    create_table :aircraft_families do |t|
      t.string :family_name
      t.string :iata_aircraft_code
      t.string :manufacturer
      t.string :category

      t.timestamps null: false
    end
  end
end
