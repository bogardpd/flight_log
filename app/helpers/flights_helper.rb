module FlightsHelper
  
  # Accepts a type and returns an icon
  def display_icon(type, raw, interpretation=nil)
    return nil unless raw && type
    if type == :airline
      if raw =~ /^\d{3}$/
        airline = Airline.find_by(numeric_code: raw)
      else
        airline = Airline.find_by(iata_airline_code: raw.strip.upcase)
      end
      return nil unless airline
      return airline_icon(airline.icao_airline_code, title: airline.airline_name)
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

  # Accepts a number 1-5 and returns a star rating
  def quality_stars(quality, inline: nil)
    quality = quality.to_i
    quality = 0 if quality < 0
    quality = 5 if quality > 5
    classes = %w(star-rating)
    inline_classes = {left: "icon-left", right: "icon-right", both: "icon-between-text"}
    classes.push(inline_classes[inline]) if inline_classes[inline]
    html = image_tag("stars/#{quality}.svg", title: "#{quality} out of 5 stars", alt: "#{quality} out of 5 stars", class: classes.join(" "))
    return html.html_safe
  end
end
