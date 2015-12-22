class TripsController < ApplicationController
  before_filter :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  layout "flight_log/flight_log"
  add_breadcrumb 'Home', 'flightlog_path'

  
  def index
    add_breadcrumb 'Trips', 'trips_path'
    @trips = Trip.uniq.joins(:flights).order("flights.departure_date")
    @trips = @trips.visitor if !logged_in? # Filter out hidden trips for visitors
    @trips_with_no_flights = Trip.where('id not in (?)',@trips)
    @title = "Trips"
    @meta_description = "A list of airplane trips Paul Bogard has taken."
    
    # Set values for sort:
    case params[:sort_category]
    when "departure"
      @sort_cat = :departure
    else
      @sort_cat = :departure
    end
    
    case params[:sort_direction]
    when "asc"
      @sort_dir = :asc
    when "desc"
      @sort_dir = :desc
    else
      @sort_dir = :desc
    end
    
    @trips.reverse! if @sort_dir == :desc
  end

  
  def show
    @logo_used = true
    @trip = Trip.find(params[:id])
    # Filter out hidden trips for visitors:
    raise ActiveRecord::RecordNotFound if (!logged_in? && @trip.hidden)
    @flights = @trip.flights
    @title = @trip.name
    @meta_description = "Maps and lists of flights on Paul Bogard's #{@trip.name} trip."
    add_breadcrumb 'Trips', 'trips_path'
    add_breadcrumb @title, "trip_path(#{params[:id]})"
    @trip_distance = total_distance(@flights)
    @section_count = Hash.new(0) # Holds a count of the number of flights in each section
    @section_final_destination = Hash.new # Holds the last destination airport code in each section
    stops_array = Array.new # Holds the origin, destination, and intermediate stops of the trip
    previous_section = nil
    previous_destination = nil
    @flights.each do |flight|
      @section_count[flight.trip_section] += 1
      @section_final_destination[flight.trip_section] = flight.destination_airport.iata_code
      unless flight.trip_section == previous_section  
        stops_array.push(previous_destination) unless previous_destination.nil?
        stops_array.push(flight.origin_airport.iata_code)
      end
      previous_section = flight.trip_section
      previous_destination = flight.destination_airport.iata_code
    end
    stops_array.push(@flights.last.destination_airport.iata_code) unless @flights.empty?
    stops_array.uniq!
    @stops = stops_array.join(',')
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find a trip with an ID of #{params[:id]}. Instead, we'll give you a list of trips."
    redirect_to trips_path
  end
  
  
  def show_section
    @logo_used = true
    @trip = Trip.find(params[:trip])
    @flights = @trip.flights.where(:trip_section => params[:section])
    @section_distance = total_distance(@flights)
    @meta_description = "Maps and lists of flights on section #{params[:section]} Paul Bogard's #{@trip.name} trip."
    @title = "#{@trip.name} (Section #{params[:section]})"
    add_breadcrumb 'Trips', 'trips_path'
    add_breadcrumb @trip.name, "trip_path(#{params[:trip]})"
    add_breadcrumb "Section #{params[:section]}", "show_section_path(#{params[:trip]}, #{params[:section]})"
  end

  
  def new
    @title = "New Trip"
    add_breadcrumb 'Trips', 'trips_path'
    add_breadcrumb 'New Trip', 'new_trip_path'
    @trip = Trip.new(:hidden => true)
  end
  
  
  def create
    @trip = Trip.new(trip_params)
    if @trip.save
      flash[:success] = "Successfully added #{params[:trip][:name]}!"
      redirect_to @trip
    else
      render 'new'
    end
  end
  
  
  def edit
    @trip = Trip.find(params[:id])
    add_breadcrumb 'Trips', 'trips_path'
    add_breadcrumb @trip.name, 'trip_path(@trip)'
    add_breadcrumb 'Edit Trip', 'edit_trip_path(@trip)'
  end
  
  
  def update
    @trip = Trip.find(params[:id])
    if @trip.update_attributes(trip_params)
      flash[:success] = "Successfully updated trip."
      redirect_to @trip
    else
      render 'edit'
    end
  end
  
  
  def destroy
    @flights = Flight.where("trip_id = :trip_id", {:trip_id => params[:id]})
    if @flights.any?
      flash[:error] = "This trip still has flights and could not be deleted. Please delete all of this trip's flights first."
      redirect_to trip_path(params[:id])
    else
      Trip.find(params[:id]).destroy
      flash[:success] = "Trip destroyed."
      redirect_to trips_path
    end
  end
  
  
  private
  
    def trip_params
      params.require(:trip).permit(:comment, :hidden, :name)
    end
    
    def logged_in_user
      redirect_to flightlog_path unless logged_in?
    end
end
