class FixAirlineOperatorName < ActiveRecord::Migration[5.0]
  def change
    rename_column :flights, :airline, :old_air_name
    rename_column :flights, :operator, :old_op_name
  end
end
