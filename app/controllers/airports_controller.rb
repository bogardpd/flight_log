# Controls {Airport} pages and actions.

class AirportsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :edit, :update, :destroy]
  
  # Shows a table of all {Airport Airports} visited.
  #
  # @return [nil]
  def index
    
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
      @maps = {
        airports_map: AirportsMap.new(:airports_map, Airport.where(iata_code: used_airport_codes)),
        frequency_map: AirportFrequencyMap.new(:frequency_map, @flights),
      }
      render_map_extension(@maps, params[:map_id], params[:extension])
    end
    
  end
  
  # Shows details for a particular {Airport} and data for all {Flight Flights}
  # which use it.
  # 
  # @return [nil]
  def show
    @logo_used = true

    @airport = Airport.find_by(slug: params[:id])
    raise ActiveRecord::RecordNotFound if (@airport.nil?)
    
    flyer_flights = flyer.flights(current_user).includes(:airline, :origin_airport, :destination_airport, :trip)
    @flights = flyer_flights.where("origin_airport_id = ? OR destination_airport_id = ?", @airport.id, @airport.id)
    
    raise ActiveRecord::RecordNotFound if (@flights.length == 0 && !logged_in?)
    
    @airport_frequency = Airport.visit_frequencies(@flights)[@airport.id]
    @total_distance = @flights.total_distance
    
    # Determine trips and sections:
    @trips_and_sections = Trip.matching_trips_and_sections(@flights)
    @trips_using_airport_flights = flyer_flights.where(trip_id: @trips_and_sections.map{|t| t[:trip_id]})
    @sections_using_airport_flights = flyer_flights.where(Trip.section_where_array(@trips_and_sections))
    
    # Sort city pair table:
    @sort = Table.sort_parse(params[:sort], :flights, :desc)
    @nonstop_flight_airports = Airport.nonstop_flight_count(@flights, @airport, *@sort)

    # Find maxima for graph scaling:
    if @flights.empty? || @nonstop_flight_airports.empty?
      @flights_maximum = 0
      @distance_maximum = 0
    else
      @flights_maximum = @nonstop_flight_airports.max_by{|i| i[:total_flights].to_i}[:total_flights]
      @distance_maximum = @nonstop_flight_airports.max_by{|i| i[:distance_mi].to_i}[:distance_mi]
    end
    
    # Create comparitive lists of airlines, aircraft, and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline)
    @operators = Airline.flight_table_data(@flights, type: :operator)
    @aircraft_families = AircraftFamily.flight_table_data(@flights)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create maps:
    @maps = {
      airport_map: FlightsMap.new(
        :airport_map,
        @flights,
        highlighted_airports: [@airport],
      ),
      sections_map: FlightsMap.new(
        :sections_map,
        @sections_using_airport_flights,
        highlighted_airports: [@airport],
      ),
      trips_map: FlightsMap.new(
        :trips_map,
        @trips_using_airport_flights,
        highlighted_airports: [@airport],
      ),
    }
    render_map_extension(@maps, params[:map_id], params[:extension])
   
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = %Q(We couldnʼt find an airport matching <span class="param-highlight">#{params[:id]}</span>. Instead, weʼll give you a list of airports.)
    redirect_to airports_path
  end
  
  # Shows a form to add an {Airport}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def new
    session[:form_location] = nil
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
        redirect_to airport_path(@airport.slug)
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
  end
  
  # Updates an existing {Airport}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def update
    @airport = Airport.find(params[:id])
    if @airport.update(airport_params)
      flash[:success] = "Successfully updated airport."
      redirect_to airport_path(@airport.slug)
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
    @airport = Airport.find(params[:id])
    @flights = Flight.where("origin_airport_id = :airport_id OR destination_airport_id = :airport_id", {airport_id: params[:id]})
    if @flights.any?
      flash[:error] = "This airport still has flights and could not be deleted. Please delete all of this airportʼs flights first."
      redirect_to airport_path(@airport.slug)
    else
      @airport.destroy
      flash[:success] = "Airport deleted."
      redirect_to airports_path
    end
  end
  
  
  private
  
  # Defines permitted {Airport} parameters.
  #
  # @return [ActionController::Parameters]
  def airport_params
    params.require(:airport).permit(:city, :slug, :iata_code, :icao_code, :country, :latitude, :longitude)
  end
  
end
