class Route < ApplicationRecord
  belongs_to :airport1, :class_name => 'Airport'
  belongs_to :airport2, :class_name => 'Airport'
  
  # Returns an array of hashes. Each hash contains an array of two airport codes
  # (sorted alphabetically), distance, and
  # number of times flown. Routes which have been flown but have
  # not had a distance defined have a value of -1 (to allow sorting).
  def self.table(logged_in = false)
    flights = logged_in ? Flight.all : Flight.visitor
    flights = flights.includes(:origin_airport, :destination_airport)
    
    route_distances = Hash.new()
    route_frequencies = Hash.new(0)
    route_array = Array.new()
    
    Route.find_by_sql("SELECT routes.distance_mi, airports1.iata_code AS iata1, airports2.iata_code AS iata2 FROM routes JOIN airports AS airports1 ON airports1.id = routes.airport1_id JOIN airports AS airports2 ON airports2.id = routes.airport2_id").map{|x| route_distances[[x.iata1,x.iata2].sort] = x.distance_mi }
        
    flights.each do |flight|
      airport_alphabetize = [flight.origin_airport.iata_code,flight.destination_airport.iata_code].sort
      route_frequencies[airport_alphabetize] += 1;
    end
    
    route_frequencies.each do |route, freq|
      route_array.push({
        route: route,
        total_flights: freq,
        distance_mi: route_distances[route] || -1
      })
    end
    
    return route_array
    
  end
end
