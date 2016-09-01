class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  @gcmap_used = false
  
  def current_region(default: :world)
    if params[:region]
      region = params[:region].to_sym
    else
      region = default
    end
  end
  
protected

  def add_breadcrumb name, url=''
    @breadcrumbs ||= []
    url = eval(url) if url =~ /_path|_url|@/
    @breadcrumbs << [name, url]
  end
  
  def self.add_breadcrumb name, url, options = {}
    before_filter options do |controller|
      controller.send(:add_breadcrumb, name, url)
    end
  end
  
  def format_date(input_date) # Also see method in application helper
    input_date.strftime("%e %b %Y")
  end
  
  def aircraft_frequency(flights)
    # Creates global variables containing the aircraft of a list of flights, and how many flights involving this list each aircraft has.
    aircraft_frequency_hash = Hash.new(0) # All aircraft start with 0 flights
    @aircraft_family_names = Hash.new
    @aircraft_family_manufacturers = Hash.new
    flights.where("aircraft_family_id IS NOT NULL").each do |flight|
      aircraft_frequency_hash[flight.iata_aircraft_code] += 1
      @aircraft_family_names[flight.iata_aircraft_code] ||= flight.family_name
      @aircraft_family_manufacturers[flight.iata_aircraft_code] ||= flight.manufacturer
    end
    @aircraft_frequency_sorted = aircraft_frequency_hash.sort_by { |aircraft, frequency| [-frequency, aircraft] }
    @aircraft_frequency_maximum = aircraft_frequency_hash.values.max
    @unknown_aircraft_flights = flights.length - flights.where("aircraft_family_id IS NOT NULL").length
  end
  
  def airline_frequency(flights)
    # Creates global variables containing the airlines of a list of flights, and how many flights involving this list each airline has.
    airline_frequency_hash = Hash.new(0) # All airlines start with 0 flights
    @airline_names = Hash.new
    flights.each do |flight|
      airline_frequency_hash[flight.iata_airline_code] += 1
      @airline_names[flight.iata_airline_code] ||= flight.airline_name
    end
    @airline_frequency_sorted = airline_frequency_hash.sort_by { |airline, frequency| [-frequency, airline] }
    @airline_frequency_maximum = airline_frequency_hash.values.max
  end
  
  def operator_frequency(flights)
    # Creates global variables containing the operators of a list of flights, and how many flights involving this list each operator has.
    operator_frequency_hash = Hash.new(0) # All operators start with 0 flights
    @operator_names = Hash.new
    if flights.where("operator_id IS NOT NULL").any?
      flights.where("operator_id IS NOT NULL").each do |flight|
        operator_frequency_hash[flight.operator_iata_airline_code] += 1
        @operator_names[flight.operator_iata_airline_code] ||= flight.operator_name
      end
      @operator_frequency_sorted = operator_frequency_hash.sort_by { |airline, frequency| [-frequency, airline] }
      @operator_frequency_maximum = operator_frequency_hash.values.max
      @unknown_operator_flights = flights.length - flights.where("operator_id IS NOT NULL").length
    else
      @operator_frequency_sorted = nil
      @operator_frequency_maximum = nil
      @unknown_operator_flights = nil
    end
  end
  
  def class_frequency(flights)
    # Creates global variables containing the classes of a list of flights, and how many flights involving this list each class has.
    class_frequency_hash = Hash.new(0) # All classes start with 0 flights
    flights.where("travel_class IS NOT NULL").each do |flight|
      class_frequency_hash[flight.travel_class] += 1
    end
    @class_frequency_sorted = class_frequency_hash.sort_by { |travel_class, frequency| [-frequency, travel_class] }
    @class_frequency_maximum = class_frequency_hash.values.max
    @unknown_class_flights = flights.length - flights.where("travel_class IS NOT NULL").length
  end

  # This calls an SQL query, and should not be used in a loop.
  def route_distance_by_iata(iata1, iata2)
    airport_ids = Array.new
    airport_ids[0] = Airport.where(:iata_code => iata1).first.try(:id)
    airport_ids[1] = Airport.where(:iata_code => iata2).first.try(:id)
    current_route = Route.where("(airport1_id = ? AND airport2_id = ?) OR (airport1_id = ? AND airport2_id = ?)", airport_ids[0], airport_ids[1], airport_ids[1], airport_ids[0])
    if current_route.present?
      return current_route.first.distance_mi
    else
      return false
    end
  end
  
  # This calls an SQL query, and should not be used in a loop.
  def route_distance_by_airport_id(airport1_id, airport2_id)
    current_route = Route.where("(airport1_id = ? AND airport2_id = ?) OR (airport1_id = ? AND airport2_id = ?)", airport1_id, airport2_id, airport2_id, airport1_id)
    if current_route.present?
      return current_route.first.distance_mi
    else
      return false
    end
  end
  
  def superlatives(flights)
    # This function takes a collection of flights and returns a superlatives collection.
    route_distances = Hash.new()
    route_hash = Hash.new()
    Route.find_by_sql("SELECT routes.distance_mi, airports1.iata_code AS iata1, airports2.iata_code AS iata2 FROM routes JOIN airports AS airports1 ON airports1.id = routes.airport1_id JOIN airports AS airports2 ON airports2.id = routes.airport2_id").map{|x| route_hash[[x.iata1,x.iata2]] = x.distance_mi }
    flights.each do |flight|
      airport_alphabetize = [flight.origin_iata_code,flight.destination_iata_code].sort
      route_distances[[airport_alphabetize[0],airport_alphabetize[1]]] = route_hash[[airport_alphabetize[0],airport_alphabetize[1]]] || route_hash[[airport_alphabetize[1],airport_alphabetize[0]]] || -1
    end
    return superlatives_collection(route_distances)
    
  end
  
  def superlatives_collection(route_distances)
    # accept a hash of distances in format distances[[airport1,airport2]] = distance and return a hash of hashes of superlative distances
    return false if route_distances.length == 0
    route_max = route_distances.max_by{|k,v| v}[1]
    route_non_zero = route_distances.select{|k,v| v > 0}
    route_min = route_non_zero.length > 0 ? route_non_zero.min_by{|k,v| v}[1] : route_max
    route_superlatives = Hash.new
    route_superlatives[:max] = route_distances.select{|k,v| v == route_max}
    route_superlatives[:min] = route_distances.select{|k,v| v == route_min}
    route_superlatives[:zero] = route_distances.select{|k,v| v == 0}
    return route_superlatives
  end
  
  def total_distance(flights)
    
    # Get set of airports used in flights and select all routes with at least one of those airports
    used_airport_ids = Set.new
    flights.each do |flight|
      used_airport_ids << flight.origin_airport_id
      used_airport_ids << flight.destination_airport_id
    end
    route_envelope = Route.where("airport1_id IN (?) OR airport2_id IN (?)", used_airport_ids, used_airport_ids)
    
    # Sort airports numerically and create hash of airport distances
    distances = Hash.new(0)
    route_envelope.each do |route|
      airport_id = Array.new
      airport_id[0] = route.airport1_id
      airport_id[1] = route.airport2_id
      airport_id.sort!
      distances[airport_id] = route.distance_mi
    end
    
    # Loop through flights and sum distances
    total_distance = 0
    flights.each do |flight|
      airport_id = Array.new
      airport_id[0] = flight.origin_airport_id
      airport_id[1] = flight.destination_airport_id
      airport_id.sort!
      total_distance += distances[airport_id]
    end
    
    return total_distance
    
  end
  
end
