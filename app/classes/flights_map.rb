class FlightsMap < Map
  
  # Initialize a map of a single flight route.
  # Params:
  # +flights+:: A collection of Flights.
  # ++highlighted_airports+:: An array of string IATA codes to highlight.
  # +region+:: The region to show. World map will be shown if region is left blank.
  def initialize(flights, highlighted_airports: nil, include_names: false, region: :world)
    @flights = flights
    @highlighted_airports = highlighted_airports ? highlighted_airports : Array.new
    @region = region
    @routes = separate_routes_by_region
    @include_names = include_names
  end
  
  private
  
    def routes_inside_region
      return @routes[:inside_region]
    end
  
    def routes_outside_region
      return @routes[:outside_region]
    end
    
    def airports_highlighted
      return @highlighted_airports
    end
  
    def separate_routes_by_region

      pairs_inside_region  = Array.new
      pairs_outside_region = Array.new
      routes = Hash.new

      @flights.each do |flight|
        # Build arrays of city pairs
        if @region == :conus 
          conus_airports = Airport.where(region_conus: true).pluck(:iata_code)
          if (!conus_airports.include?(flight.origin_iata_code) || !conus_airports.include?(flight.destination_iata_code))
            pairs_outside_region.push([flight.origin_iata_code, flight.destination_iata_code].sort)
          else
            pairs_inside_region.push([flight.origin_iata_code, flight.destination_iata_code].sort)
          end
        else
          pairs_inside_region.push([flight.origin_iata_code, flight.destination_iata_code].sort)
        end  
      end

      routes[:inside_region]  = compressed_routes(pairs_inside_region)
      routes[:outside_region] = compressed_routes(pairs_outside_region)
    
      return routes
    
    end
  
end