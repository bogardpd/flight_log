class PkPassesController < ApplicationController
  before_action :logged_in_user

  require 'net/imap'
  
  def index
    @title = "Import Boarding Passes"
    
    # Determine an appropriate trip to use:
    begin
      @trip = Trip.find(params[:trip_id])
    rescue ActiveRecord::RecordNotFound
      if Trip.where(hidden: true).any?
        @trip = Trip.where(hidden: true).order(:created_at).last
      elsif Trip.any?
        @trip = Trip.order(:created_at).last
      else
        flash[:record_not_found] = "No trips have been created yet, so we can’t import a boarding pass. Please create a trip."
        redirect_to new_trip_path
      end
    end
    
    check_email_for_boarding_passes
    @import_pass_variables = import_pass_variables
    
  end
  
  def destroy
    PKPass.find(params[:id]).destroy
    flash[:success] = "Pass destroyed."
    redirect_to trip_path(Trip.find(params[:trip_id]))
  end
  
  private
  
    
  
end