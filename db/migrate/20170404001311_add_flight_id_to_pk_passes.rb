class AddFlightIdToPkPasses < ActiveRecord::Migration[5.0]
  def change
    add_column :pk_passes, :flight_id, :integer
  end
end
