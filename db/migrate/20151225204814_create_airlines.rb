class CreateAirlines < ActiveRecord::Migration[5.0]
  def change
    create_table :airlines do |t|
      t.string :iata_airline_code, null: false
      t.string :airline_name, null: false
      t.boolean :is_only_operator

      t.timestamps null: false
    end
  end
end
