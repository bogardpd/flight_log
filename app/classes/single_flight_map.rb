class SingleFlightMap < Map
  
  # Initialize a map of a single flight route.
  # Params:
  # +flight+:: An instance of the Flight model
  def initialize(flight)
    @route = [[flight.origin_airport.iata_code, flight.destination_airport.iata_code].join("-")]
  end
  
  private
    
    def airport_options
      return "*"
    end
    
    def routes_inside_region
      return @route
    end
  
end