class FlightsMap < Map

  # Initialize a map of flight routes.
  # Params:
  # +flights+:: A collection of Flights.
  # ++highlighted_airports+:: An array of string IATA codes to highlight.
  # +region+:: The region to show. World map will be shown if region is left blank.
  def initialize(flights, highlighted_airports: nil, include_names: false, region: [""])
    @flights = flights
    @highlighted_airports = highlighted_airports ? highlighted_airports.pluck(:id) : Array.new
    @airports_inside_region = Airport.in_region_hash(region).keys | @highlighted_airports
    @routes = separate_routes_by_region
    @include_names = include_names
  end
  
  private
  
  # Returns an array of airport IDs
  def airports_normal
    return @routes[:extra_airports]
  end

  # Returns an array of airport IDs
  def airports_highlighted
    return @highlighted_airports
  end

  # Returns true if highlighted airports should display names, fals otherwise
  def gcmap_include_highlighted_airport_names?
    return @include_names
  end

  # Returns an array of routes in the form of [[airport_1_id, airport_2_id]]. The IDs should be sorted within each pair.
  def routes_normal
    return @routes[:inside_region]
  end

  # Returns an array of routes in the form of [[airport_1_id, airport_2_id]]. The IDs should be sorted within each pair.
  def routes_out_of_region
    return @routes[:outside_region]
  end

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
    
    routes[:inside_region]     = pairs_inside_region.uniq
    routes[:outside_region]    = pairs_outside_region.uniq
    routes[:extra_airports]    = ((pairs_outside_region.flatten - pairs_inside_region.flatten) & @airports_inside_region).uniq # Airports that are in the region, but only have routes to outside of the region.
    return routes
  
  end
  
end