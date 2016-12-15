module FlightsHelper
  
  def display_airline_by_code(iata_code)
    return nil unless iata_code.present?
    airline = Airline.where(iata_airline_code: iata_code) 
    if airline.length > 0
      html = link_to(iata_mono(iata_code) + image_tag(airline_icon_path(iata_code), alt: iata_code, title: airline.first.airline_name, class: 'airline_icon icon_between_text') + airline.first.airline_name, airline_path(iata_code))
    else
      html = iata_mono(iata_code)
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
