class RemoveTripOrderFromFlights < ActiveRecord::Migration
  def up
    remove_column :flights, :trip_order
  end

  def down
    add_column :flights, :trip_order, :integer
  end
end
