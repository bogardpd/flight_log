module FlightsHelper
  
  def route_string(flight_list, *args)
    route_inside_region = ""
    route_outside_region = ""
    
    pairs_inside_region = Array.new
    pairs_outside_region = Array.new
    
    flight_list.each do |flight|
      # Build array of city pairs
      if (args[0] == "conus" && (!flight.origin_airport.region_conus || !flight.destination_airport.region_conus))
        pairs_outside_region.push([flight.origin_airport.iata_code,flight.destination_airport.iata_code].sort)
      else
        pairs_inside_region.push([flight.origin_airport.iata_code,flight.destination_airport.iata_code].sort)
      end  
    end
    
    pairs_inside_region = pairs_inside_region.uniq.sort_by{|k| [k[0],k[1]]}
    pairs_outside_region = pairs_outside_region.uniq.sort_by{|k| [k[0],k[1]]}
    

    previous_pair0 = nil
    pairs_inside_region.each do |pair|
      if pair[0] == previous_pair0
        route_inside_region += "/#{pair[1]}"
      else
        route_inside_region += ",#{pair[0]}-#{pair[1]}"
      end
      previous_pair0 = pair[0]
    end  
    
    previous_pair0 = nil
    pairs_outside_region.each do |pair|
      if pair[0] == previous_pair0
        route_outside_region += "/#{pair[1]}"
      else
        route_outside_region += ",o:noext,#{pair[0]}-#{pair[1]}"
      end
      previous_pair0 = pair[0]
    end
    
    if pairs_outside_region.length > 0
      route = "c:%23FF7777#{route_outside_region},c:red#{route_inside_region}"
    elsif args[0] == :uncolored
      route = route_inside_region
    else
      route = "c:red#{route_inside_region}"
    end
    
  end
  
  def airport_highlight(airport)
    return airport.blank? ? "" : "m:p:ring11:black,#{airport},"
  end
  
  def route_highlight(route,highlight)
    return "c:%23FF7777,#{route},c:red,w:2,#{highlight}"
  end
  
end
