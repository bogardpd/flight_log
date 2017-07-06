class HighlightedRoutesMap < Map
  
  # Initialize a map of flight routes with some routes highlighted.
  # Params:
  # +flights+:: A collection of Flights
  # +highlighted_route: A collection of Flights whose routes will be highlighted.
  def initialize(flights, highlighted_routes)
    @flights = flights
    @highlighted_routes = highlighted_routes
  end
  
  private
  
    def routes_highlighted
      return collected_routes(@highlighted_routes)
    end
    
    def routes_unhighlighted
      return collected_routes(@flights)
    end
    
    # Compile a Flight collection into a compressed set of routes.
    # Params:
    # +flights+:: A collection of Flights
    def collected_routes(flights)
      pairs = Array.new
      flights.each do |flight|
        pairs.push([flight.origin_airport.iata_code, flight.destination_airport.iata_code].sort)
      end
      return compressed_routes(pairs)
    end
  
end