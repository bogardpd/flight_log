class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  @gcmap_used = false
  
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
  
  def route_distance_by_airport_id(airport1_id, airport2_id)
    current_route = Route.where("(airport1_id = ? AND airport2_id = ?) OR (airport1_id = ? AND airport2_id = ?)", airport1_id, airport2_id, airport2_id, airport1_id)
    if current_route.present?
      return current_route.first.distance_mi
    else
      return false
    end
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
  
  def superlatives(flights)
    # This function takes a collection of flights and returns a superlatives collection.
    route_distances = Hash.new()
    flights.each do |flight|
      airport_alphabetize = [flight.origin_airport.iata_code,flight.destination_airport.iata_code].sort
      route_distances[[airport_alphabetize[0],airport_alphabetize[1]]] = route_distance_by_iata(airport_alphabetize[0],airport_alphabetize[1]) if route_distance_by_iata(airport_alphabetize[0],airport_alphabetize[1])
    end
    return superlatives_collection(route_distances)
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
