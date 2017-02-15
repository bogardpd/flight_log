module FlightsHelper
  
  def display_airline_by_code(iata_code)
    return nil unless iata_code.present?
    airline = Airline.where(iata_airline_code: iata_code) 
    if airline.length > 0
      html = %Q(#{iata_mono(iata_code)}<div class="supplemental_info">#{airline.first.airline_name}#{image_tag(airline_icon_path(iata_code), alt: iata_code, title: airline.first.airline_name, class: 'airline_icon icon_right')}</div>) 
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
      html += %Q(<div class="supplemental_info">#{airport.first.city}</div>).html_safe
    end
    return html
  end
  
  # Accepts a type and returns an icon
  def display_icon(type, raw, interpretation=nil)
    return nil unless raw && type
    path = {
      :airline => lambda{|data|
        airline_icon_path(data.strip)
      },
      :selectee => lambda{|data|
        'tpc.png' if data.to_i == 3        
      }
    }
    if path[type]
      return image_tag(path[type].call(raw), class: 'airline_icon', title: interpretation).html_safe
    end
    return nil
  end
  
end
