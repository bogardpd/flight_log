class PkPassesController < ApplicationController
  before_action :logged_in_user
  
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
        flash[:warning] = "No trips have been created yet, so we can’t import a boarding pass. Please create a trip."
        redirect_to new_trip_path
      end
    end
    
    empty_trips = Trip.with_no_flights.map{|trip| [trip.name, trip.id]}
    
    @trips = empty_trips.concat(Trip.with_departure_dates(current_user, current_user).reverse.map{|trip| ["#{trip.name} / #{Flight.format_date(trip.departure_date)}", trip.id]})
    @passes = PKPass.pass_summary_list
    @flight_passes = PKPass.flights_with_updated_passes
    @flights = flyer.flights(current_user).where(id: @flight_passes.keys)
    
    check_email_for_boarding_passes      
    
  end
  
  def change_trip
    redirect_to import_boarding_passes_path(trip_id: params[:trip_id])
  end
  
  def destroy
    PKPass.find(params[:id]).destroy
    flash[:success] = "Pass destroyed."
    redirect_to import_boarding_passes_path
  end
  
  private
  
    
  
end