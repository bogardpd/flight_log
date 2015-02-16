class AddCountryToAirports < ActiveRecord::Migration
  def change
    add_column :airports, :country, :string
  end
end
