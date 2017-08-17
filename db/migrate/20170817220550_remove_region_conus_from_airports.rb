class RemoveRegionConusFromAirports < ActiveRecord::Migration[5.0]
  def change
    remove_column :airports, :region_conus, :boolean
  end
end
