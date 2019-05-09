# Defines a map of {Flight}s with some flights highlighted.

class HighlightedRoutesMap < Map
  
  # Initialize a map of {Flight}s with some flights highlighted.
  # 
  # @param flights [Array<Flight>] a collection of {Flight}s to show
  #   unhighlighted
  # @param highlighted_routes [Array<Flight>] a collection of {Flight}s whose
  #   routes will be highlighted
  def initialize(flights, highlighted_routes)
    @flights = flights

    @highlighted_routes = collected_routes(highlighted_routes)
    @unhighlighted_routes = collected_routes(flights) - @highlighted_routes
  end

  private
  
  # Compile a Flight collection into a compressed set of routes.
  # 
  # @param flights [Array<Flight>] a collection of Flights
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def collected_routes(flights)
    return flights.map{|flight| [flight.origin_airport_id, flight.destination_airport_id].sort}.uniq
  end

  # Returns the map description
  #
  # @return [String] the map description
  def map_description
    return "Map of flight routes with some routes emphasized, created by Paul Bogard’s Flight Historian"
  end

  # Creates an array of numerically-sorted pairs of airport IDs for routes that
  # should be emphasized.
  # 
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def routes_highlighted
    return @highlighted_routes
  end
  
  # Creates an array of numerically-sorted pairs of airport IDs for routes that
  # should be de-emphasized.
  # 
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def routes_unhighlighted
    return @unhighlighted_routes
  end
  
end