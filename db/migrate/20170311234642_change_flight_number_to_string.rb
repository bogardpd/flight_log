class ChangeFlightNumberToString < ActiveRecord::Migration[5.0]
  def up
    change_column :flights, :flight_number, :string
  end
  def down
    change_column :flights, :flight_number, :integer
  end
end
