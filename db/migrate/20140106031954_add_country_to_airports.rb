class AddCountryToAirports < ActiveRecord::Migration[5.0]
  def change
    add_column :airports, :country, :string
  end
end
