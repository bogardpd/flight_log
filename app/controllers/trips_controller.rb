class TripsController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  add_breadcrumb 'Home', 'root_path'

  
  def index
    add_breadcrumb 'Trips', 'trips_path'
    add_admin_action view_context.link_to("Add New Trip", new_trip_path)
    @trips = Trip.with_departure_dates(logged_in?)

    @trips_with_no_flights = Trip.with_no_flights
    @title = "Trips"
    @meta_description = "A list of airplane trips Paul Bogard has taken."
    
    if @trips.any?
    
      # Set values for sort:
      sort_params = sort_parse(params[:sort], %w(departure), :desc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
      @trips.reverse! if @sort_dir == :desc
    
    end
  end

  
  def show
    @logo_used = true
    @trip = Trip.find(params[:id])
    # Filter out hidden trips for visitors:
    raise ActiveRecord::RecordNotFound if (!logged_in? && @trip.hidden)
    @flights = Flight.flights_table.where(trip_id: @trip)
    @title = @trip.name
    @meta_description = "Maps and lists of flights on Paul Bogardʼs #{@trip.name} trip."
    
    add_breadcrumb 'Trips', 'trips_path'
    add_breadcrumb @title, "trip_path(#{params[:id]})"
    
    add_admin_action view_context.link_to("Delete Trip", :trip, :method => :delete, :data => {:confirm => "Are you sure you want to delete #{@trip.name}?"}, :class => 'warning') if @flights.length == 0
    add_admin_action view_context.link_to("Edit Trip", edit_trip_path(@trip))
    add_admin_action view_context.link_to("Add Flight", new_flight_path(:trip_id => @trip))
    add_admin_action view_context.link_to("Import Passes", import_boarding_passes_path(trip_id: @trip))
    
    if logged_in? && @trip.hidden
      check_email_for_boarding_passes
    end
    
    add_message(:warning, "This trip is hidden!") if @trip.hidden
    add_message(:info, "You have boarding passes you can #{view_context.link_to("import", import_boarding_passes_path(trip_id: @trip))}!") if PKPass.where(flight_id: nil).any?
    
    @trip_distance = total_distance(@flights)
    @section_count = Hash.new(0) # Holds a count of the number of flights in each section
    @section_final_destination = Hash.new # Holds the last destination airport code in each section
    stops = Array.new # Holds the origin, destination, and intermediate stops of the trip
    previous_section = nil
    previous_destination = nil
    @flights.each do |flight|
      @section_count[flight.trip_section] += 1
      @section_final_destination[flight.trip_section] = flight.destination_iata_code
      unless flight.trip_section == previous_section  
        stops.push(previous_destination) unless previous_destination.nil?
        stops.push(flight.origin_iata_code)
      end
      previous_section = flight.trip_section
      previous_destination = flight.destination_iata_code
    end
    stops.push(@flights.last.destination_iata_code) unless @flights.empty?
    stops.uniq!
    
    # Create map
    @map = FlightsMap.new(@flights, highlighted_airports: stops, include_names: true)

    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "We couldnʼt find a trip with an ID of #{params[:id]}. Instead, weʼll give you a list of trips."
      redirect_to trips_path
  end
  
  
  def show_section
    @logo_used = true
    @trip = Trip.find(params[:trip])
    
    add_message(:warning, "This trip is hidden!") if @trip.hidden
    
    @flights = Flight.flights_table.where(trip_id: @trip, trip_section: params[:section])
    @section_distance = total_distance(@flights)
    if @flights.any?
      stops = [@flights.first.origin_iata_code,@flights.last.destination_iata_code]
    else
      stops = Array.new
    end
    @map = FlightsMap.new(@flights, highlighted_airports: stops, include_names: true)
    @meta_description = "Maps and lists of flights on section #{params[:section]} of Paul Bogardʼs #{@trip.name} trip."
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
      flash[:error] = "This trip still has flights and could not be deleted. Please delete all of this tripʼs flights first."
      redirect_to trip_path(params[:id])
    else
      Trip.find(params[:id]).destroy
      flash[:success] = "Trip destroyed."
      redirect_to trips_path
    end
  end
  
  
  private
  
    def trip_params
      params.require(:trip).permit(:comment, :hidden, :name, :purpose)
    end
    
end
