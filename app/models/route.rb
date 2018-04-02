class Route < ApplicationRecord
  belongs_to :airport1, :class_name => "Airport"
  belongs_to :airport2, :class_name => "Airport"
  
  ARROW_ONE_WAY_PLAINTEXT = "⇒"
  ARROW_TWO_WAY_PLAINTEXT = "⇔"
  ARROW_ONE_WAY_HTML = %Q(<span class="route-arrow">#{ARROW_ONE_WAY_PLAINTEXT}</span>).html_safe
  ARROW_TWO_WAY_HTML = %Q(<span class="route-arrow">#{ARROW_TWO_WAY_PLAINTEXT}</span>).html_safe
  
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
      distance = distance_by_airport(Airport.find(airport_ids[0]), Airport.find(airport_ids[1]))
      return distance.present? ? distance : false
    end
  end
  
  # Given two airports, returns the distance in statute miles between them.
  # This calls an SQL query, and should not be used in a loop.
  def self.distance_by_airport(airport_1, airport_2)
    current_route = Route.where("(airport1_id = ? AND airport2_id = ?) OR (airport1_id = ? AND airport2_id = ?)", airport_1, airport_2, airport_2, airport_1)
    if current_route.present?
      return current_route.first.distance_mi
    else
      coordinates_1 = airport_1.coordinates
      coordinates_2 = airport_2.coordinates
      return false unless coordinates_1.present? && coordinates_2.present?
      
      distance = distance_by_coordinates(coordinates_1, coordinates_2)
      return false unless distance.present?
      
      # Try to save new route:
      new_route = Route.new
      airport_ids = [airport_1.id, airport_2.id].sort
      new_route.airport1_id = airport_ids.first
      new_route.airport2_id = airport_ids.last
      new_route.distance_mi = distance
      new_route.save      
      
      return distance
    end
  end
  
  # Accepts two coordinates (floating point [latitude,longitude] arrays), and
  # returns the great circle distance between them (in integer miles) using
  # the haversine fomula.
  def self.distance_by_coordinates(coord_orig, coord_dest)
    return nil unless coord_orig.present? && coord_dest.present?
    deg_to_rad = Math::PI / 180
    radius = 3958.7613 # mean radius (miles)
    phi_1 = coord_orig[0] * deg_to_rad
    phi_2 = coord_dest[0] * deg_to_rad
    delta_phi = (coord_dest[0]-coord_orig[0]) * deg_to_rad
    delta_lambda = (coord_dest[1]-coord_orig[1]) * deg_to_rad
    
    a = Math.sin(delta_phi/2)**2 + Math.cos(phi_1) * Math.cos(phi_2) * Math.sin(delta_lambda/2)**2
    distance = 2 * radius * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    return distance.to_i
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
        distance_mi: route_distances[route] || distance_by_iata(route.first, route.last) || -1
      })
    end
    
    return route_array.sort_by{|r| [-r[:flight_count], r[:route][0], r[:route][1]]}
    
  end
  
end
