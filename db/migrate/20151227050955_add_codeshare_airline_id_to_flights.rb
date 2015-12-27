class AddCodeshareAirlineIdToFlights < ActiveRecord::Migration
  def change
    add_column :flights, :codeshare_airline_id, :integer
    rename_column :flights, :codeshare_airline, :old_cs_name
  end
end
