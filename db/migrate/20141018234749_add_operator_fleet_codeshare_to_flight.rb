class AddOperatorFleetCodeshareToFlight < ActiveRecord::Migration
  def change
    add_column :flights, :codeshare_airline, :string
    add_column :flights, :codeshare_flight_number, :integer
    add_column :flights, :operator, :string
    add_column :flights, :fleet_number, :string
  end
end
