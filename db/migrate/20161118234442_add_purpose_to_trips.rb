class AddPurposeToTrips < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :purpose, :string
  end
end
