class AddAirlineOperatorIdsToFlights < ActiveRecord::Migration[5.0]
  def change
    add_column :flights, :airline_id, :integer
    add_column :flights, :operator_id, :integer
  end
end
