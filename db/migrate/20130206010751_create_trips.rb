class CreateTrips < ActiveRecord::Migration[5.0]
  def change
    create_table :trips do |t|
      t.string :name
      t.boolean :hidden
      t.text :comment

      t.timestamps
    end
  end
end
