module FlightsHelper
  
  def display_airline_by_code(iata_code)
    return nil unless iata_code.present?
    html = iata_mono(iata_code)
    airline = Airline.where(iata_airline_code: iata_code) 
    if airline.length > 0
      html += " #{airline.first.airline_name}"
    end
    html.html_safe
  end
  
  def display_airport_by_code(iata_code)
    return nil unless iata_code.present?
    html = iata_mono(iata_code)
    airport = Airport.where(iata_code: iata_code) 
    if airport.length > 0
      html += " #{airport.first.city}"
    end
    html.html_safe
  end
  
end
