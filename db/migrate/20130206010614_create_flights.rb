class CreateFlights < ActiveRecord::Migration[5.0]
  def change
    create_table :flights do |t|
      t.integer :origin_airport_id
      t.integer :destination_airport_id
      t.integer :trip_id
      t.integer :trip_order
      t.date :departure_date
      t.string :airline
      t.integer :flight_number
      t.string :aircraft_family
      t.string :aircraft_variant
      t.string :tail_number
      t.string :travel_class
      t.text :comment

      t.timestamps
    end
  end
end
