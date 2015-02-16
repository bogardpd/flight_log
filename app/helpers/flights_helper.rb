module FlightsHelper
  
  def route_string(flight_list, *args)
    route = "";
    previous_trip_id = nil;
    previous_destination_airport_iata_code = nil;
    new_section_next_flight = false
    flight_list.each do |flight|
      if (args[0] == "conus" && (!flight.origin_airport.region_conus || !flight.destination_airport.region_conus))
        route += "o:noext," + flight.origin_airport.iata_code + "-" + flight.destination_airport.iata_code + ","
        new_section_next_flight = true;
      elsif (flight.trip.id == previous_trip_id && flight.origin_airport.iata_code == previous_destination_airport_iata_code && !new_section_next_flight)
        route = route.chomp(",") + "-" + flight.destination_airport.iata_code + ","
        new_section_next_flight = false
      else
        route += flight.origin_airport.iata_code + "-" + flight.destination_airport.iata_code + ","
        new_section_next_flight = false
      end
      previous_trip_id = flight.trip.id
      previous_destination_airport_iata_code = flight.destination_airport.iata_code
    end
    route = route.chomp(",")
  end
  
  def airport_highlight(airport)
    return airport.blank? ? "" : "m:p:ring11:black,#{airport},"
  end
  
  def route_highlight(route,highlight)
    return "c:purple,#{route},c:red,w:2,#{highlight}"
  end
  
end
