class AddIcaoCodeToAirports < ActiveRecord::Migration[5.0]
  def change
    add_column :airports, :icao_code, :string
  end
end
