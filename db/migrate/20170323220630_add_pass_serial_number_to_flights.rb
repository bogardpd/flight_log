class AddPassSerialNumberToFlights < ActiveRecord::Migration[5.0]
  def change
    add_column :flights, :pass_serial_number, :string
  end
end
