class AddNumericCodeToAirlines < ActiveRecord::Migration[5.0]
  def change
    add_column :airlines, :numeric_code, :string
  end
end
