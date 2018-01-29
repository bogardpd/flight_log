class RemovePassSerialNumberFromFlights < ActiveRecord::Migration[5.0]
  def change
    remove_column :flights, :pass_serial_number, :string
    remove_index :pk_passes, name: 'index_pk_passes_on_serial_number'
  end
end
