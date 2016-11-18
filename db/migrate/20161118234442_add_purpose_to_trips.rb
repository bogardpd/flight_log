class AddPurposeToTrips < ActiveRecord::Migration
  def change
    add_column :trips, :purpose, :string
  end
end
