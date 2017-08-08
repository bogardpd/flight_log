class AdminController < ApplicationController
  before_action :logged_in_user
  
  add_breadcrumb "Home", "root_path"
  add_breadcrumb "Admin", "admin_path"
  
  def admin
    
  end
  
  def annual_flight_summary
    add_breadcrumb "Annual Flight Summary", annual_flight_summary_path
    @title = "Annual Flight Summary"
    @flight_summary = Flight.by_year
  end
  
  def boarding_pass_validator
    add_breadcrumb "Boarding Pass Validator", boarding_pass_validator_path
    @title = "Boarding Pass Validator"
    @pass_flights = Flight.select(:id, :boarding_pass_data).where("boarding_pass_data IS NOT NULL").order(:departure_utc)
  end
  
end
