class HighlightedRoutesMap < Map
  
  # Initialize a map of flight routes with some routes highlighted.
  # Params:
  # +flights+:: A collection of Flights
  # +highlighted_route: A collection of Flights whose routes will be highlighted.
  def initialize(flights, highlighted_routes)
    @flights = flights

    @highlighted_routes = collected_routes(highlighted_routes)
    @unhighlighted_routes = collected_routes(flights) - @highlighted_routes
  end

  private
  
  # Compile a Flight collection into a compressed set of routes.
  # Params:
  # +flights+:: A collection of Flights
  def collected_routes(flights)
    return flights.map{|flight| [flight.origin_airport_id, flight.destination_airport_id].sort}.uniq
  end

  def map_description
    return "Map of flight routes with some routes emphasized, created by Paul Bogard’s Flight Historian"
  end

  # Returns an array of routes in the form of [[airport_1_id, airport_2_id]]. The IDs should be sorted within each pair.
  def routes_highlighted
    return @highlighted_routes
  end
  
  # Returns an array of routes in the form of [[airport_1_id, airport_2_id]]. The IDs should be sorted within each pair.
  def routes_unhighlighted
    return @unhighlighted_routes
  end
  
end