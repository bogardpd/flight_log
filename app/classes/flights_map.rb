# Defines a map of multple {Flight Flights}.

class FlightsMap < Map

  # Initialize a map of multiple {Flight Flights}.
  # 
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @param highlighted_airports [Array<Airport>] a collection of {Airport Airports} to
  #   highlight
  # @param include_names [Boolean] whether or not to show city names
  #   on highlighted {Airport Airports}
  def initialize(id, flights, highlighted_airports: nil, include_names: false)
    @id = id
    @flights = flights
    @route_pairs = @flights.pluck(:origin_airport_id, :destination_airport_id).map{|pair| pair.sort}.uniq
    @highlighted_airports = highlighted_airports ? highlighted_airports.pluck(:id) : Array.new
    @normal_airports = (@route_pairs.flatten.uniq | @highlighted_airports) - @highlighted_airports
    @include_names = include_names
  end
  
  private
  
  # Returns an array of airport IDs for airports with no special formatting.
  #
  # @return [Array<Number>] airport IDs
  def airports_normal
    return @normal_airports
  end

  # Returns an array of airport IDs for airports that should be emphasized.
  #
  # @return [Array<Number>] airport IDs
  def airports_highlighted
    return @highlighted_airports
  end

  # Returns true if highlighted airports should display names, false otherwise.
  #
  # @return [Boolean] whether to display names on highlighted airports
  def gcmap_include_highlighted_airport_names?
    return @include_names
  end

  # Returns the map description.
  #
  # @return [String] the map description
  def map_description
    return "Map of flight routes, created by Paul Bogard’s Flight Historian"
  end

  # Returns a string to use in the class for the map.
  #
  # @return [String] the map type
  def map_type
    return "flights-map"
  end

  # Creates an array of numerically-sorted pairs of airport IDs for routes with
  # no special formatting.
  # 
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def routes_normal
    return @route_pairs
  end
  
end