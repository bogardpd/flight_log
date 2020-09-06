class AddBoardingPassDataToFlights < ActiveRecord::Migration[5.0]
  def change
    add_column :flights, :boarding_pass_data, :text
  end
end
