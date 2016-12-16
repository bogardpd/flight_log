class AdminController < ApplicationController
  before_action :logged_in_user
  
  add_breadcrumb 'Home', 'root_path'
  add_breadcrumb 'Admin', 'admin_path'
  
  def admin
    
  end
  
  def boarding_pass_validator
    add_breadcrumb 'Boarding Pass Validator', boarding_pass_validator_path
    @pass_flights = Flight.select(:id, :boarding_pass_data).where("boarding_pass_data IS NOT NULL").order(:departure_utc)
  end
  
  private
  
    def logged_in_user
      redirect_to root_path unless logged_in?
    end
    
end
