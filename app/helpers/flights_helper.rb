module FlightsHelper
  
  # Accepts a type and returns an icon
  def display_icon(type, raw, interpretation=nil)
    return nil unless raw && type
    if type == :airline
      if raw =~ /^\d{3}$/
        airline = Airline.where(numeric_code: raw)
        return airline_icon(airline.first.iata_airline_code) if airline.length > 0
      else
        return airline_icon(raw) 
      end
      return airline_icon(raw) 
    elsif type == :selectee
      return image_tag("tpc.png", title: interpretation, class: "airline-icon") if raw.to_i == 3
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
