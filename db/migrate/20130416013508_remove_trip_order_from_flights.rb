class RemoveTripOrderFromFlights < ActiveRecord::Migration[5.0]
  def up
    remove_column :flights, :trip_order
  end

  def down
    add_column :flights, :trip_order, :integer
  end
end
