class CreateAirports < ActiveRecord::Migration
  def change
    create_table :airports do |t|
      t.string :iata_code
      t.string :city
      t.boolean :region_conus

      t.timestamps
    end
  end
end
