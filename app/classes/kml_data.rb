class KMLData

  # Initialize a KML file.
  # Params:
  # +flights+:: A collection of Flight objects
  def initialize(flights: nil)
    @flights = flights
    if flights
      @routes = flights.includes(:origin_airport, :destination_airport).map{|f| [f.origin_airport.iata_code, f.destination_airport.iata_code].sort}.uniq
      @airports = airports(flights)
    end
  end

  # Return the XML for a KML document.
  def xml
    
  end

  private

  def airports(flights)
    airport_ids = flights.pluck(:origin_airport_id, :destination_airport_id).flatten.uniq.sort
    airport_details = Airport.find(airport_ids).pluck(:iata_code, :city, :latitude, :longitude).sort_by{|x| x[0]}
    airport_hash = Hash.new();
    airport_details.each do |airport|
      airport_hash[airport[0]] = {city: airport[1], latitude: airport[2], longitude: airport[3] }
    end
    return airport_hash
  end
    

end