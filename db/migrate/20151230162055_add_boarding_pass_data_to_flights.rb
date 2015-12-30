class AddBoardingPassDataToFlights < ActiveRecord::Migration
  def change
    add_column :flights, :boarding_pass_data, :text
  end
end
