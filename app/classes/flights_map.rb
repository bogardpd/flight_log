class FlightsMap < Map
  
  # Initialize a map of a single flight route.
  # Params:
  # +flights+:: A collection of Flights
  # +region+:: The region to show. World map will be shown if region is left blank.
  def initialize(flights, region: :world)
    @flights = flights
    @region = region
    @routes = separate_routes_by_region
  end
  
  private
  
    def routes_inside_region
      return @routes[:inside_region]
    end
  
    def routes_outside_region
      return @routes[:outside_region]
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

      routes[:inside_region]  = compress_routes(pairs_inside_region)
      routes[:outside_region] = compress_routes(pairs_outside_region)
    
      return routes
    
    end
    
    def compress_routes(pairs)
      routes = Array.new
      pairs = pairs.uniq.sort_by{|k| [k[0],k[1]]}
      previous_origin = nil
      route_string = nil
      pairs.each do |pair|
        if pair[0] == previous_origin && route_string
          route_string += "/#{pair[1]}"
        else
          routes.push(route_string) if route_string
          route_string = "#{pair[0]}-#{pair[1]}"
        end
        routes.push(route_string) if (pair == pairs.last && route_string)
        previous_origin = pair[0]
      end
      return routes
    end
    
  
end