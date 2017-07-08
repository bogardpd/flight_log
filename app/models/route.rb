class Route < ApplicationRecord
  belongs_to :airport1, :class_name => 'Airport'
  belongs_to :airport2, :class_name => 'Airport'
  
  # Given two IATA airport codes, returns the distance in statute miles
  # between them. This calls an SQL query, and should not be used in a loop.
  def self.distance_by_iata(iata1, iata2)
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
  
  # Given two airport IDs, returns the distance in statute miles between them.
  # This calls an SQL query, and should not be used in a loop.
  def self.distance_by_airport_id(airport1_id, airport2_id)
    current_route = Route.where("(airport1_id = ? AND airport2_id = ?) OR (airport1_id = ? AND airport2_id = ?)", airport1_id, airport2_id, airport2_id, airport1_id)
    if current_route.present?
      return current_route.first.distance_mi
    else
      return false
    end
  end
  
  # Returns an array of hashes. Each hash contains an array of two airport codes
  # (sorted alphabetically), distance, and number of times flown, sorted by
  # number of times flown descending. Routes which have been flown but have
  # not had a distance defined have a value of -1 (to allow sorting).
  def self.flight_count(flights)
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
        flight_count: freq,
        distance_mi: route_distances[route] || -1
      })
    end
    
    return route_array.sort_by{|r| [-r[:flight_count], r[:route][0], r[:route][1]]}
    
  end
  
end
