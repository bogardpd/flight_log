class CreatePkPasses < ActiveRecord::Migration[5.0]
  def change
    create_table :pk_passes do |t|
      t.string :serial_number
      t.text :pass_json
      t.datetime :received

      t.timestamps
    end
    add_index :pk_passes, :serial_number
  end
end
