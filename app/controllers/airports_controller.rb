class AirportsController < ApplicationController
  before_filter :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  add_breadcrumb 'Home', 'root_path'
  
  def index
    add_breadcrumb 'Airports', 'airports_path'
    @title = "Airports"
    @meta_description = "Maps and lists of airports Paul Bogard has visited, and how often he's visited them."
    if logged_in?
      @flights = Flight.chronological
    else
      @flights = Flight.visitor.chronological
    end
    
    @airport_array = Array.new
    
    if @flights.any?
      
      airport_frequency = frequency_array(@flights)
    
      # Set values for sort:
      case params[:sort_category]
      when "country"
        @sort_cat = :country
      when "city"
        @sort_cat = :city
      when "code"
        @sort_cat = :code
      when "visits"
        @sort_cat = :visits
      else
        @sort_cat = :visits
      end
    
      case params[:sort_direction]
      when "asc"
        @sort_dir = :asc
      when "desc"
        @sort_dir = :desc
      else
        @sort_dir = :desc
      end
    
      sort_mult = (@sort_dir == :asc ? 1 : -1)
    
      # Select all airports in the database with at least one flight:
      @airports = Airport.find(airport_frequency.keys)
      @airports_with_no_flights = Airport.where('id not in (?)',airport_frequency.keys)
    
      # Create arrays of airports:
      @airports.each do |airport|
        # Create world airport array:
        @airport_array.push({:id => airport.id, :iata_code => airport.iata_code, :city => airport.city, :country => airport.country, :frequency => airport_frequency[airport.id]})
        # Create CONUS airport array:
        if (airport.region_conus) then
          @airport_conus_array.push({:id => airport.id, :iata_code => airport.iata_code, :city => airport.city, :frequency => airport_frequency[airport.id]})
        end
      end
    
      # Find maxima for graph scaling:
      @visits_maximum = @airport_array.max_by{|i| i[:frequency]}[:frequency]
    
      # Sort route table:
      case @sort_cat
      when :country
        if @sort_dir == :asc
          @airport_array = @airport_array.sort_by {|airport| [airport[:country], airport[:city]]}
        else
          @airport_array = @airport_array.sort {|a, b| [b[:country], a[:city]] <=> [a[:country], b[:city]] }
        end
      when :city
        @airport_array = @airport_array.sort_by {|airport| airport[:city]}
        @airport_array.reverse! if @sort_dir == :desc
      when :code
        @airport_array = @airport_array.sort_by {|airport| airport[:iata_code]}
        @airport_array.reverse! if @sort_dir == :desc
      when :visits
        @airport_array = @airport_array.sort_by { |airport| [sort_mult*airport[:frequency], airport[:city]] }
      end
    
    end
    
  end
  
  
  def show
    @logo_used = true
    if params[:id].to_i > 0
      @airport = Airport.find(params[:id])
    else
      @airport = Airport.where(:iata_code => params[:id]).first
      raise ActiveRecord::RecordNotFound if (@airport.nil?) #all_flights will fail if code does not exist, so check here.
    end
    
    # Set values for sort:
    case params[:sort_category]
    when "city"
      @sort_cat = :city
    when "code"
      @sort_cat = :code
    when "flights"
      @sort_cat = :flights
    when "distance"
      @sort_cat = :distance
    else
      @sort_cat = :flights
    end
    
    case params[:sort_direction]
    when "asc"
      @sort_dir = :asc
    when "desc"
      @sort_dir = :desc
    else
      @sort_dir = :desc
    end
    sort_mult = (@sort_dir == :asc ? 1 : -1)
    
    @flights = @airport.all_flights(logged_in?)
    raise ActiveRecord::RecordNotFound if (@flights.length == 0 && !logged_in?)
    trip_array = Array.new
    @sections = Array.new
    section_where_array = Array.new
    pair_totals = Hash.new(0)
    pair_cities = Hash.new
    pair_countries = Hash.new
    pair_distances = Hash.new
    @direct_flight_airports = Array.new
    prev_trip_id = nil
    prev_section_id = nil
    @flights.each do |flight|
      trip_array.push(flight.trip_id)
      unless (flight.trip_id == prev_trip_id && flight.trip_section == prev_section_id)
        @sections.push( {:trip_id => flight.trip_id, :trip_name => flight.trip.name, :trip_section => flight.trip_section, :departure => flight.departure_date} )
      end
      prev_trip_id = flight.trip_id
      prev_section_id = flight.trip_section
      section_where_array.push("(trip_id = #{flight.trip_id.to_i} AND trip_section = #{flight.trip_section.to_i})")
      
      # Create hash of the other airports on flights to/from this airport and their counts
      if (flight.origin_airport.iata_code == @airport.iata_code)
        pair_totals[flight.destination_airport.iata_code] += 1
        pair_cities[flight.destination_airport.iata_code] = flight.destination_airport.city
        pair_countries[flight.destination_airport.iata_code] = flight.destination_airport.country
        pair_distances[flight.destination_airport.iata_code] = route_distance_by_iata(flight.origin_airport.iata_code,flight.destination_airport.iata_code) || -1
      else
        pair_totals[flight.origin_airport.iata_code] += 1
        pair_cities[flight.origin_airport.iata_code] = flight.origin_airport.city
        pair_countries[flight.origin_airport.iata_code] = flight.origin_airport.country
        pair_distances[flight.origin_airport.iata_code] = route_distance_by_iata(flight.origin_airport.iata_code,flight.destination_airport.iata_code) || -1
      end
    end
    trip_array = trip_array.uniq.sort
    @sections.uniq!
    @trips = Trip.find(trip_array).sort_by{ |trip| trip.flights.first.departure_date }
    @trips_using_airport_flights = Flight.chronological.where(:trip_id => trip_array)
    @sections_using_airport_flights = Flight.where(section_where_array.join(' OR '))
    @airport_frequency = frequency_array(@trips_using_airport_flights)
    @pair_maximum = pair_totals.length > 0 ? pair_totals.values.max : 1
    
    # Create direct flight airport array sorted by count descending, city ascending:
    pair_totals.each do |airport, count|
      @direct_flight_airports << {:iata_code => airport, :total_flights => count, :city => pair_cities[airport], :distance_mi => pair_distances[airport], :country => pair_countries[airport]}
    end
    
    # Find maxima for graph scaling:
    @flights_maximum = @flights.length == 0 ? 0 : @direct_flight_airports.max_by{|i| i[:total_flights].to_i}[:total_flights]
    @distance_maximum = @flights.length == 0 ? 0 : @direct_flight_airports.max_by{|i| i[:distance_mi].to_i}[:distance_mi]
    
    # Sort city pair table:
    case @sort_cat
    when :city
      @direct_flight_airports = @direct_flight_airports.sort_by {|value| value[:city]}
      @direct_flight_airports.reverse! if @sort_dir == :desc
    when :code
      @direct_flight_airports = @direct_flight_airports.sort_by {|value| value[:iata_code]}
      @direct_flight_airports.reverse! if @sort_dir == :desc
    when :flights
      @direct_flight_airports = @direct_flight_airports.sort_by {|value| [sort_mult*value[:total_flights],value[:city]]}
    when :distance
      @direct_flight_airports = @direct_flight_airports.sort_by {|value| [sort_mult*value[:distance_mi],value[:city]]}
    end
    
    # Create comparitive lists of airlines, aircraft, and classes:
    airline_frequency(@flights)
    aircraft_frequency(@flights)
    class_frequency(@flights)
    
    
    
    @title = @airport.iata_code
    @meta_description = "Maps and lists of Paul Bogard's flights through #{@airport.iata_code} - #{@airport.city}."
    
    add_breadcrumb 'Airports', 'airports_path'
    add_breadcrumb @title, "airport_path(@airport.iata_code)"
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find an airport with an ID of #{params[:id]}. Instead, we'll give you a list of airports."
    redirect_to airports_path
  end
  
  
  def new
    @title = "New Airport"
    add_breadcrumb 'Airports', 'airports_path'
    add_breadcrumb 'New Airport', 'new_airport_path'
    @airport = Airport.new
  end
  
  
  def create
    @airport = Airport.new(airport_params)
    if @airport.save
      flash[:success] = "Successfully added #{params[:airport][:iata_code]}!"
      redirect_to @airport
    else
      render 'new'
    end
  end
  
  
  def edit
    @airport = Airport.find(params[:id])
    add_breadcrumb 'Airports', 'airports_path'
    add_breadcrumb @airport.iata_code, 'airport_path(@airport)'
    add_breadcrumb 'Edit Airport', 'edit_airport_path(@airport)'
  end
  
  
  def update
    @airport = Airport.find(params[:id])
    if @airport.update_attributes(airport_params)
      flash[:success] = "Successfully updated airport."
      redirect_to @airport
    else
      render 'edit'
    end
  end
  
  
  def destroy
    @flights = Flight.where("origin_airport_id = :airport_id OR destination_airport_id = :airport_id", {:airport_id => params[:id]})
    if @flights.any?
      flash[:error] = "This airport still has flights and could not be deleted. Please delete all of this airport's flights first."
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
  
    def airport_params
      params.require(:airport).permit(:city, :iata_code, :country, :region_conus)
    end
  
    def logged_in_user
      redirect_to root_path unless logged_in?
    end
    
    
    def frequency_array(flight_array)
      flight_array = flight_array.chronological
      airport_frequency = Hash.new(0) # All airports start with 0 flights
      @airport_array = Array.new
      @airport_conus_array = Array.new
      previous_trip_id = nil;
      previous_trip_section = nil;
      previous_destination_airport_iata_code = nil;
      flight_array.each do |flight|
        unless (flight.trip.id == previous_trip_id && flight.trip_section == previous_trip_section && flight.origin_airport.iata_code == previous_destination_airport_iata_code)
          # This is not a layover, so count this origin airport
          airport_frequency[flight.origin_airport_id] += 1
        end
        airport_frequency[flight.destination_airport_id] += 1
        previous_trip_id = flight.trip.id
        previous_trip_section = flight.trip_section
        previous_destination_airport_iata_code = flight.destination_airport.iata_code
      end
      return airport_frequency
    end
 
=begin
    
    def aircraft_frequency(flights)
      # Creates global variables containing the aircraft of a list of flights, and how many flights involving this list each aircraft has.
      aircraft_frequency_hash = Hash.new(0) # All aircraft start with 0 flights
      flights.where("aircraft_family IS NOT NULL").each do |flight|
        aircraft_frequency_hash[flight.aircraft_family] += 1
      end
      @aircraft_frequency_sorted = aircraft_frequency_hash.sort_by { |aircraft, frequency| [-frequency, aircraft] }
      @aircraft_frequency_maximum = aircraft_frequency_hash.values.max
      @unknown_aircraft_flights = flights.count - flights.where("aircraft_family IS NOT NULL").count
    end
    
    def airline_frequency(flights)
      # Creates global variables containing the airlines of a list of flights, and how many flights involving this list each airline has.
      airline_frequency_hash = Hash.new(0) # All airlines start with 0 flights
      flights.each do |flight|
        airline_frequency_hash[flight.airline] += 1
      end
      @airline_frequency_sorted = airline_frequency_hash.sort_by { |airline, frequency| [-frequency, airline] }
      @airline_frequency_maximum = airline_frequency_hash.values.max
    end
    
    def class_frequency(flights)
      # Creates global variables containing the classes of a list of flights, and how many flights involving this list each class has.
      class_frequency_hash = Hash.new(0) # All classes start with 0 flights
      flights.where("travel_class IS NOT NULL").each do |flight|
        class_frequency_hash[flight.travel_class] += 1
      end
      @class_frequency_sorted = class_frequency_hash.sort_by { |travel_class, frequency| [-frequency, travel_class] }
      @class_frequency_maximum = class_frequency_hash.values.max
      @unknown_class_flights = flights.count - flights.where("travel_class IS NOT NULL").count
    end

=end
    
end
