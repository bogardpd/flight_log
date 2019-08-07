# Controls {Trip} pages and actions, including {#show_section trip sections}.
class TripsController < ApplicationController
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  
  # Shows a table of all {Trip Trips} flown.
  #
  # @return [nil]
  def index
    add_breadcrumb "Trips", trips_path
    @sort = Table.sort_parse(params[:sort], :departure, :desc)
    @trips = Trip.with_departure_dates(flyer, current_user, *@sort)
    @trips_with_no_flights = Trip.with_no_flights
  end

  # Shows details for a particular {Trip} and its {Flight Flights}.
  # 
  # {Trip} details:
  # * comments
  # 
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}, separated by {#show_section trip section}
  # * the total distance flown
  #
  # @return [nil]
  def show
    @logo_used = true
    @trip = Trip.find(params[:id])
    raise ActiveRecord::RecordNotFound if (flyer != current_user && @trip.hidden)
    @flights = Flight.where(trip_id: @trip).includes(:airline, :origin_airport, :destination_airport, :trip).order(:departure_utc)
    
    add_breadcrumb "Trips", trips_path
    add_breadcrumb @trip.name, trip_path(params[:id])
    
    add_message(:warning, "This trip is hidden!") if @trip.hidden

    if logged_in? && @trip.hidden
      check_email_for_boarding_passes
      add_message(:info, "You have boarding passes you can #{view_context.link_to("import", new_flight_menu_path(trip_id: @trip))}!") if PKPass.where(flight_id: nil).any?
    end
    
    @trip_distance = Route.total_distance(@flights)
    @section_count = Hash.new(0) # Holds a count of the number of flights in each section
    @section_final_destination = Hash.new # Holds the last destination airport code in each section
    stops = Array.new # Holds the origin, destination, and intermediate stops of the trip
    previous_section = nil
    previous_destination = nil
    @flights.each do |flight|
      @section_count[flight.trip_section] += 1
      @section_final_destination[flight.trip_section] = flight.destination_airport
      unless flight.trip_section == previous_section  
        stops.push(previous_destination) unless previous_destination.nil?
        stops.push(flight.origin_airport)
      end
      previous_section = flight.trip_section
      previous_destination = flight.destination_airport
    end
    stops.push(@flights.last.destination_airport) unless @flights.empty?
    stops.uniq!
    
    # Create map
    @map = FlightsMap.new(@flights, highlighted_airports: stops, include_names: true)

  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find a trip with an ID of #{params[:id]}. Instead, weʼll give you a list of trips."
    redirect_to trips_path
  end
  
  # Shows flight data for a particular section of a {Trip}.
  #
  # Trip sections are used to distinguish between layovers and multiple visits
  # to a given airport within a given {Trip}, in the situation where two
  # flights are chronologically consecutive and the destination {Airport} of
  # the first flight is the same as the origin of the second. If these two
  # flights share the same {Trip} and trip section, then the time between the
  # two flights is a layover and only counts as one visit to shared {Airport}.
  # Otherwise, the traveler left the airport in between the flights, and it
  # counts as two separate visits to the shared {Airport}.
  # 
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}
  # * the total distance flown
  # * the layover ratio (the total distance flown divided by the distance
  #   between the first origin and final destination {Airport Airports}), if
  #   this section has more than one flight.
  #
  # @return [nil]
  def show_section
    @logo_used = true
    @trip = Trip.find(params[:trip])
    @section = params[:section]
    
    raise ActiveRecord::RecordNotFound if (flyer != current_user && @trip.hidden)
    
    add_message(:warning, "This trip is hidden!") if @trip.hidden
    
    @flights = Flight.where(trip_id: @trip, trip_section: @section).includes(:airline, :origin_airport, :destination_airport, :trip).order(:departure_utc)
    raise ActiveRecord::RecordNotFound unless @flights.any?

    @section_distance = Route.total_distance(@flights)
    @layover_ratio = @trip.layover_ratio(@section)
    stops = [@flights.first.origin_airport,@flights.last.destination_airport]
    
    @map = FlightsMap.new(@flights, highlighted_airports: stops, include_names: true)
    
    add_breadcrumb "Trips", trips_path
    add_breadcrumb @trip.name, trip_path(params[:trip])
    add_breadcrumb "Section #{@section}", show_section_path(params[:trip], @section)
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find a matching trip section. Instead, weʼll give you a list of trips."
    redirect_to trips_path
  end
  
  # Shows a form to add a {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def new
    add_breadcrumb "Trips", trips_path
    add_breadcrumb "New Trip", new_trip_path
    @trip = Trip.new(:hidden => true)
  end
  
  # Creates a new {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def create
    @trip = current_user.trips.new(trip_params)
    if @trip.save
      flash[:success] = "Successfully added #{params[:trip][:name]}!"
      redirect_to @trip
    else
      render "new"
    end
  end
  
  # Shows a form to edit an existing {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def edit
    @trip = Trip.find(params[:id])
    add_breadcrumb "Trips", trips_path
    add_breadcrumb @trip.name, trip_path(@trip)
    add_breadcrumb "Edit Trip", edit_trip_path(@trip)
  end
  
  # Updates an existing {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def update
    @trip = Trip.find(params[:id])
    if @trip.update_attributes(trip_params)
      flash[:success] = "Successfully updated trip."
      redirect_to @trip
    else
      render "edit"
    end
  end
  
  # Deletes an existing {Trip}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
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
  
  # Defines permitted {Airline} parameters.
  #
  # @return [ActionController::Parameters]
  def trip_params
    params.require(:trip).permit(:comment, :hidden, :name, :purpose)
  end
    
end
