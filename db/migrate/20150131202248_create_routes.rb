class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.integer :airport1_id
      t.integer :airport2_id
      t.integer :distance_mi

      t.timestamps
    end
  end
end
