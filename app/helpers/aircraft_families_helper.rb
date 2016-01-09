module AircraftFamiliesHelper
  
  # Return HTML for an illustration of a particular aircraft type, if that illustration exists
  # Params:
  # +iata_aircraft_code+:: IATA code of the aircraft to illustrate
  def aircraft_illustration(iata_aircraft_code)
    image_location = "aircraft_illustrations/" + iata_aircraft_code + ".jpg"
    if Rails.application.assets.find_asset(image_location)
      html = "<div class=\"illustration_container\">"
      html += image_tag(image_location, alt: "#{iata_aircraft_code} illustration")
      html += "</div>"
      html += "<div class=\"illustration_credit\">Illustration by " + link_to("Norebbo", "http://www.norebbo.com/") + "</div>"
      
      return html.html_safe
    else
      return nil
    end
  end
  
end