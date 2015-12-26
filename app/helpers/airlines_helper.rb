module AirlinesHelper
  
  def airline_icon_path(iata_airline_code)
    image_location = "flight_log/airline_icons/" + iata_airline_code + ".png"
    if Rails.application.assets.find_asset(image_location)
      image_location
    else
      "flight_log/airline_icons/unknown-airline.png"
    end
  end
  
  def iata_airline_code_display(iata_airline_code)
    iata_airline_code.split('-').first
  end
  
end