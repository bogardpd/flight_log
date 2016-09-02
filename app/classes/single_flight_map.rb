class SingleFlightMap < Map
  
  # Initialize a map of a single flight route.
  # Params:
  # +flight+:: An instance of the Flight model
  def initialize(flight)
    @codes = [flight.origin_airport.iata_code, flight.destination_airport.iata_code]
    @route = [@codes.join("-")]
  end
  
  private
    
    def airport_options
      return "*"
    end
    
    def alt_tag
      "Map of flight route between #{@codes[0]} and #{@codes[1]}"
    end
    
    def routes_inside_region
      return @route
    end
  
end