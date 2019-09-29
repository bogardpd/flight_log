# Defines a model for flight routes.
#
# Note that this specifically refers to flight routes, and not routes in the
# Ruby on Rails routing sense.
#
# The Route model is largely used to maintain a table of route distances
# between {Airport} pairs; most interaction that the application has with a
# Route is actually internally managed as the pair of {Airport Airports}
# associated with a {Flight}.
class Route < ApplicationRecord
  belongs_to :airport1, :class_name => "Airport"
  belongs_to :airport2, :class_name => "Airport"
  
  # The plain text arrow used between airport pairs on one way routes.
  ARROW_ONE_WAY_PLAINTEXT = "⇒"
  # The plain text arrow used between airport pairs on two way routes.
  ARROW_TWO_WAY_PLAINTEXT = "⇔"
  # The HTML arrow used between airport pairs on one way routes.
  ARROW_ONE_WAY_HTML = ActionController::Base.helpers.content_tag(:span, ARROW_ONE_WAY_PLAINTEXT, class: %w(route-arrow))
  # The HTML arrow used between airport pairs on two way routes.
  ARROW_TWO_WAY_HTML = ActionController::Base.helpers.content_tag(:span, ARROW_TWO_WAY_PLAINTEXT, class: %w(route-arrow))
  
  # Given two {Airport Airports}, returns the distance in statute miles
  # between them. The haversine formula is used to calculate the distance.
  # 
  # This calls an SQL query, and should not be used in a loop.
  #
  # @param airport_1 [Airport] an {Airport}
  # @param airport_2 [Airport] an {Airport}
  # @return [Integer] the distance between the airports in statute miles
  def self.distance_by_airport(airport_1, airport_2)
    current_route = Route.find_by("(airport1_id = :a1_id AND airport2_id = :a2_id) OR (airport1_id = :a2_id AND airport2_id = :a1_id)", a1_id: airport_1.id, a2_id: airport_2.id)
    if current_route.present?
      return current_route.distance_mi
    else
      coordinates_1 = airport_1.coordinates
      coordinates_2 = airport_2.coordinates
      return nil unless coordinates_1.present? && coordinates_2.present?
      
      distance = distance_by_coordinates(coordinates_1, coordinates_2)
      return nil unless distance.present?
      
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
  
  # Given two latitude/longitude pairs, returns the distance in statute miles
  # between them. The haversine formula is used to calculate the distance.
  #
  # @param coord_orig [Array<Float>] an array containing a latitude and a longitude in decimal degrees
  # @param coord_dest [Array<Float>] an array containing a latitude and a longitude in decimal degrees
  # @return [Integer] the distance between the coordinates in statute miles
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

  # Returns an array of routes, with a hash for each airport pair containing
  # the distance in statute miles and number of {Flight Flights} on that route
  # (in either direction), sorted by number of flights descending.
  #
  # Used on various "index" and "show" views to generate a table of routes and
  # their flight counts.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights} to
  #   calculate Route flight counts for
  # @param sort_category [:flights, :distance] the category to sort the array
  #   by
  # @return [Array<Hash>] details for each Route flown
  def self.flight_table_data(flights, sort_category=nil, sort_direction=nil)
    return nil unless flights.any?
    
    route_distances = flights.route_distances

    route_frequencies = flights.includes(:origin_airport, :destination_airport).map{|f| [f.origin_airport,f.destination_airport].sort_by{|a| a.slug}}.reduce(Hash.new(0)){|hash, pair| hash[pair] += 1; hash}

    route_array = route_frequencies.map{|pair, freq| {route: pair, flight_count: freq, distance_mi: (route_distances[[pair.first.id,pair.last.id].sort] || distance_by_coordinates(pair.first.coordinates, pair.last.coordinates) || nil) }}

    sort_mult = (sort_direction == :desc ? -1 : 1)
    case sort_category
    when :flights
      route_array.sort_by!{|route| [sort_mult*(route[:flight_count] || 0), -(route[:distance_mi] || -1)]}
    when :distance
      route_array.sort_by!{|route| [sort_mult*(route[:distance_mi] || -1), -(route[:flight_count] || 0)]}
    else
      route_array.sort_by!{|route| [(-route[:flight_count] || 0), route[:route][0], route[:route][1]]}
    end

    return route_array
    
  end

  private

  
  
end
