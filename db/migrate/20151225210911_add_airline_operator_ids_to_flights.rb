class AddAirlineOperatorIdsToFlights < ActiveRecord::Migration
  def change
    add_column :flights, :airline_id, :integer
    add_column :flights, :operator_id, :integer
  end
end
