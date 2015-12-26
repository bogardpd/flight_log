class FixAirlineOperatorName < ActiveRecord::Migration
  def change
    rename_column :flights, :airline, :old_air_name
    rename_column :flights, :operator, :old_op_name
  end
end
