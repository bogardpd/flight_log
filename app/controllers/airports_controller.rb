# Controls {Airport} pages and actions.

class AirportsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :edit, :update, :destroy]
  
  # Shows a table of all {Airport Airports} visited.
  #
  # @return [nil]
  def index
    add_breadcrumb "Airports", airports_path
    add_admin_action view_context.link_to("Add New Airport", new_airport_path)
    @title = "Airports"
    @meta_description = "Maps and lists of airports Paul Bogard has visited, and how often heʼs visited them."
    @flights = flyer.flights(current_user).includes(:origin_airport, :destination_airport)
    @airports = Array.new
    
    if @flights.any?
      
      @sort = Table.sort_parse(params[:sort], :visits, :desc)
      @airports = Airport.visit_table_data(@flights, *@sort)
      used_airport_codes = @airports.map{|a| a[:iata_code]}.uniq.compact
      if logged_in?
        @airports_with_no_flights = Airport.where.not(iata_code: used_airport_codes).order(:city)
      end
      
      # Create maps:
      @region = current_region(default: [])
      @airports_map  = AirportsMap.new(Airport.where(iata_code: used_airport_codes), region: @region)
      @frequency_map = AirportFrequencyMap.new(@flights, region: @region)
      
    end
    
  end
  
  # Shows details for a particular {Airport} and data for all {Flight Flights}
  # which use it.
  # 
  # {Airport} details:
  # * city (and name if needed for disambiguation)
  # * latitude and longitude
  # * IATA and ICAO codes
  # * a {https://www.pbogard.com/projects/terminal-silhouettes terminal silhouette}
  # 
  # {Flight} data:
  # * a table of {Flight Flights} with a {FlightsMap}
  # * the total distance flown
  # * a table of {TripsController#show_section trip sections} with a {FlightsMap} of all {Flight Flights} in those sections
  # * a table of {Trip Trips} with a {FlightsMap} of all {Flight Flights} in those trips
  # * a table of {Airline Airlines}
  # * a table of {AirlinesController#show_operator operators}
  # * a table of {AircraftFamily AircraftFamilies}
  # * a table of {FlightsController#show_class classes}
  # * the longest and shortest {Flight}
  #
  # @return [nil]
  # @see https://www.pbogard.com/projects/terminal-silhouettes Terminal Silhouettes
  def show
    @logo_used = true
    if params[:id].to_i > 0
      @airport = Airport.find(params[:id])
    else
      @airport = Airport.where(:iata_code => params[:id]).first
      raise ActiveRecord::RecordNotFound if (@airport.nil?)
    end
    
    flyer_flights = flyer.flights(current_user).includes(:airline, :origin_airport, :destination_airport, :trip)
    @flights = flyer_flights.where("origin_airport_id = ? OR destination_airport_id = ?", @airport.id, @airport.id)
    
    raise ActiveRecord::RecordNotFound if (@flights.length == 0 && !logged_in?)
    
    @airport_frequency = Airport.visit_frequencies(@flights)[@airport.id]
    @total_distance = Route.total_distance(@flights)
    
    # Determine trips and sections:
    @trips_and_sections = Trip.matching_trips_and_sections(@flights)
    @trips_using_airport_flights = flyer_flights.where(trip_id: @trips_and_sections.map{|t| t[:trip_id]})
    @sections_using_airport_flights = flyer_flights.where(Trip.section_where_array(@trips_and_sections))
    
    # Sort city pair table:
    @sort = Table.sort_parse(params[:sort], :flights, :desc)
    @direct_flight_airports = Airport.direct_flight_count(@flights, @airport, *@sort)

    # Find maxima for graph scaling:
    if @flights.empty? || @direct_flight_airports.empty?
      @flights_maximum = 0
      @distance_maximum = 0
    else
      @flights_maximum = @direct_flight_airports.max_by{|i| i[:total_flights].to_i}[:total_flights]
      @distance_maximum = @direct_flight_airports.max_by{|i| i[:distance_mi].to_i}[:distance_mi]
    end
    
    # Create comparitive lists of airlines, aircraft, and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline)
    @operators = Airline.flight_table_data(@flights, type: :operator)
    @aircraft_families = AircraftFamily.flight_table_data(@flights)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create maps:
    @region = current_region(default: [])
    @airport_map  = FlightsMap.new(@flights, highlighted_airports: [@airport], region: @region)
    @sections_map = FlightsMap.new(@sections_using_airport_flights, highlighted_airports: [@airport], region: @region)
    @trips_map    = FlightsMap.new(@trips_using_airport_flights, highlighted_airports: [@airport], region: @region)
    
    @title = @airport.iata_code
    @meta_description = "Maps and lists of Paul Bogardʼs flights through #{@airport.iata_code} – #{@airport.city}."
    
    add_breadcrumb "Airports", airports_path
    add_breadcrumb @title, airport_path(@airport.iata_code)
    
    add_admin_action view_context.link_to("Delete Airport", @airport, method: :delete, data: {confirm: "Are you sure you want to delete #{@airport.iata_code}?"}, :class => "warning") if @flights.length == 0
    add_admin_action view_context.link_to("Edit Airport", edit_airport_path(@airport))
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find an airport with an ID of #{params[:id]}. Instead, weʼll give you a list of airports."
    redirect_to airports_path
  end
  
  # Shows a form to add an {Airport}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def new
    session[:form_location] = nil
    @title = "New Airport"
    add_breadcrumb "Airports", airports_path
    add_breadcrumb "New Airport", new_airport_path
    @airport = Airport.new
  end
  
  # Creates a new {Airport}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def create
    @airport = Airport.new(airport_params)
    if @airport.save
      @airport.coordinates # Look up coordinates for new airport
      flash[:success] = "Successfully added #{params[:airport][:iata_code]}!"
      if session[:form_location]
        form_location = session[:form_location]
        session[:form_location] = nil
        redirect_to form_location
      else
        redirect_to @airport
      end
    else
      if session[:form_location]
        render "flights/new_undefined_airport"
      else
        render "new"
      end
    end
  end
  
  # Shows a form to edit an existing {Airport}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def edit
    session[:form_location] = nil
    @airport = Airport.find(params[:id])
    add_breadcrumb "Airports", airports_path
    add_breadcrumb @airport.iata_code, airport_path(@airport)
    add_breadcrumb "Edit Airport", edit_airport_path(@airport)
  end
  
  # Updates an existing {Airport}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def update
    @airport = Airport.find(params[:id])
    if @airport.update_attributes(airport_params)
      flash[:success] = "Successfully updated airport."
      redirect_to @airport
    else
      render "edit"
    end
  end
  
  # Deletes an existing {Airport}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def destroy
    @flights = Flight.where("origin_airport_id = :airport_id OR destination_airport_id = :airport_id", {:airport_id => params[:id]})
    if @flights.any?
      flash[:error] = "This airport still has flights and could not be deleted. Please delete all of this airportʼs flights first."
      redirect_to airport_path(params[:id])
    else
      if (Airport.exists?(params[:id]))
        Airport.find(params[:id]).destroy
      else
        Airport.where(:iata_code => params[:id]).first.destroy
      end
      flash[:success] = "Airport destroyed."
      redirect_to airports_path
    end
  end
  
  
  private
  
  # Defines permitted {Airport} parameters.
  #
  # @return [ActionController::Parameters]
  def airport_params
    params.require(:airport).permit(:city, :iata_code, :icao_code, :country, :latitude, :longitude)
  end
  
end
