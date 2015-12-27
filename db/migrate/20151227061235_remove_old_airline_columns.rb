class RemoveOldAirlineColumns < ActiveRecord::Migration
  def change
    remove_column :flights, :old_air_name
    remove_column :flights, :old_cs_name
    remove_column :flights, :old_op_name
  end
end
