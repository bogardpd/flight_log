class RemoveFlightIdFromPkPasses < ActiveRecord::Migration[5.2]
  def change
    remove_column :pk_passes, :flight_id, :integer
  end
end
