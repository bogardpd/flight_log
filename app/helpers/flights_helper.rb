module FlightsHelper
  
  def display_airline_by_code(iata_code)
    return nil unless iata_code.present?
    airline = Airline.where(iata_airline_code: iata_code) 
    if airline.length > 0
      html = %Q(#{code_mono(iata_code)}<div class="supplemental-info">#{airline.first.airline_name}#{image_tag(airline_icon_path(iata_code), alt: iata_code, title: airline.first.airline_name, class: 'airline_icon icon_right')}</div>) 
    else
      html = code_mono(iata_code)
    end
    html.html_safe
  end
  
  def display_airport_by_code(iata_code)
    return nil unless iata_code.present?
    html = code_mono(iata_code)
    airport = Airport.where(iata_code: iata_code) 
    if airport.length > 0
      html += %Q(<div class="supplemental-info">#{airport.first.city}</div>).html_safe
    end
    return html
  end
  
  # Accepts a type and returns an icon
  def display_icon(type, raw, interpretation=nil)
    return nil unless raw && type
    path = {
      :airline => lambda{|data|
        if raw =~ /^\d{3}$/
          airline = Airline.where(numeric_code: data)
          airline_icon_path(airline.first.iata_airline_code) if airline.length > 0
        else
          airline_icon_path(data.strip)
        end
      },
      :selectee => lambda{|data|
        'tpc.png' if data.to_i == 3        
      }
    }
    if path[type]
      path = path[type].call(raw)
      return image_tag(path, class: 'airline_icon', title: interpretation).html_safe if path
    end
    return nil
  end
  
  def format_radio_text(label, text_hash)
    label = %Q(<span class="label">#{label}</span>)
    if text_hash.nil?
      text = %Q(<span class="radio-empty">(blank)</span>)
    else
      text = Array.new
      text.push(%Q(<code class="radio-code-block">#{text_hash[:code_block].chars.each_slice(24).map(&:join).join("<br/>")}</code>)) if text_hash[:code_block]
      text.push(%Q(<span class="radio-code">#{text_hash[:code]}</span>)) if text_hash[:code]
      text.push(text_hash[:text]) if text_hash[:text]
      text = text.join("&emsp;")
    end
    return [label, text].join("<br/>")
  end
end
