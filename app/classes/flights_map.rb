# Defines a map of multple {Flight}s.

class FlightsMap < Map

  # Initialize a map of multiple {Flight}s.
  # 
  # @param flights [Array<Flight>] a collection of {Flight}s
  # @param highlighted_airports [Array<Airport>] a collection of {Airport}s to
  #   highlight
  # @param include_names [Boolean] whether or not to show city names
  #   on highlighted {Airport}s
  # @param region [Array<String>] the ICAO prefixes to show (e.g. ["K","PH"]).
  #   World map will be shown if region is left blank.
  # @see Map#gcmap_regions
  def initialize(flights, highlighted_airports: nil, include_names: false, region: [""])
    @flights = flights
    @highlighted_airports = highlighted_airports ? highlighted_airports.pluck(:id) : Array.new
    @airports_inside_region = Airport.in_region_hash(region).keys | @highlighted_airports
    @routes = separate_routes_by_region
    @include_names = include_names
  end
  
  private
  
  # Returns an array of airport IDs for airports with no special formatting.
  #
  # @return [Array<Number>] airport IDs
  def airports_normal
    return @routes[:extra_airports]
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

  # Creates an array of numerically-sorted pairs of airport IDs for routes with
  # no special formatting.
  # 
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def routes_normal
    return @routes[:inside_region]
  end

  # Creates an array of numerically-sorted pairs of airport IDs for routes that
  # are not in the current region.
  # 
  # @return [Array<Array>] an array of routes in the form of [[airport_1_id,
  #   airport_2_id]].
  def routes_out_of_region
    return @routes[:outside_region]
  end

  # Splits routes into those entirely within the map region, and those with at
  # least one airport outside of it.
  #
  # @return [Hash{symbol => Array}] A hash with three keys. :inside_region and
  #   :outside_region each contain an array of routes in the form of
  #   [[airport_1_id, airport_2_id]]. :extra_airports contains an array of
  #   airport IDs which are in the region, but only have routes to airports
  #   outside of the region.
  def separate_routes_by_region

    pairs_inside_region  = Array.new
    pairs_outside_region = Array.new
    routes = Hash.new
    
    @flights.each do |flight|
      route = [flight.origin_airport_id, flight.destination_airport_id].sort
      if @airports_inside_region.include?(route[0]) && @airports_inside_region.include?(route[1])
        pairs_inside_region.push(route)
      else
        pairs_outside_region.push(route)
      end
    end
    
    routes[:inside_region]  = pairs_inside_region.uniq
    routes[:outside_region] = pairs_outside_region.uniq
    routes[:extra_airports] = ((pairs_outside_region.flatten - pairs_inside_region.flatten) & @airports_inside_region).uniq # Airports that are in the region, but only have routes to outside of the region.
    return routes
  
  end
  
end