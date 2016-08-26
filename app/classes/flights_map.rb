class FlightsMap < Map
  
  def initialize(flights, region: nil)
    # Setting region to nil will result in a world map with no region switching links.
    @flights = flights
    @region = region
    @routes = separate_routes_by_region
    @airport_options = "b:disc5:black"
  end
  
  private
  
    def routes_inside_region
      return @routes[:inside_region]
    end
  
    def routes_outside_region
      return @routes[:outside_region]
    end
  
    def separate_routes_by_region
      routes_inside_region = Array.new
      routes_outside_region = Array.new

      pairs_inside_region = Array.new
      pairs_outside_region = Array.new

      @flights.each do |flight|
        # Build array of city pairs
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

      pairs_inside_region = pairs_inside_region.uniq.sort_by{|k| [k[0],k[1]]}
      pairs_outside_region = pairs_outside_region.uniq.sort_by{|k| [k[0],k[1]]}

      previous_origin = nil
      route_string = nil
      pairs_inside_region.each do |pair|
        if pair[0] == previous_origin && route_string
          route_string += "/#{pair[1]}"
        else
          routes_inside_region.push(route_string) if route_string
          route_string = "#{pair[0]}-#{pair[1]}"
        end
        routes_inside_region.push(route_string) if (pair == pairs_inside_region.last && route_string)
        previous_origin = pair[0]
      end
    
      previous_origin = nil
      route_string = nil
      pairs_outside_region.each do |pair|
        if pair[0] == previous_origin && route_string
          route_string += "/#{pair[1]}"
        else
          routes_outside_region.push(route_string) if route_string
          route_string = "#{pair[0]}-#{pair[1]}"
        end
        routes_outside_region.push(route_string) if (pair == pairs_outside_region.last && route_string)
        previous_origin = pair[0]
      end
    
      routes = Hash.new
      routes[:inside_region] = routes_inside_region
      routes[:outside_region] = routes_outside_region
    
      return routes
    
    end
  
end