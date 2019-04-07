class SingleFlightMap < Map
  
  # Initialize a map of a single flight route.
  # Params:
  # +flight+:: An instance of the Flight model
  def initialize(flight)
    @codes = [flight.origin_airport.iata_code, flight.destination_airport.iata_code]
    @flight = flight
  end
  
  private

  # Returns an array of routes in the form of [[airport_1_id, airport_2_id]]. The IDs should be sorted within each pair.
  def routes_normal
    return [[@flight.origin_airport_id, @flight.destination_airport_id].sort]
  end

  def map_description
    "Map of flight route between #{@codes[0]} and #{@codes[1]}"
  end

  # Returns a string of Great Circle Mapper airport options.
  def gcmap_airport_options
    return "*"
  end
  
end