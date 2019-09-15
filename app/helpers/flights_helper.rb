# Defines helper methods for {Flight} views.
module FlightsHelper
  
  # Creates a nested list for an aircraft type and all of its parents.
  #
  # @param types [Array] the output of an {AircraftFamily#type_and_parent_types}
  #   call
  # @return [ActiveSupport::SafeBuffer, nil] a nested list of links to aircraft
  #   types
  def aircraft_type_tree(types, top_level=true)
    types.reverse! if top_level
    
    ul_classes = ["aircraft-type-tree"]
    ul_classes.push("aircraft-type-tree-top") if top_level
    output = content_tag(:ul, class: ul_classes) do
      subtypes = types[1..-1]
      li_classes = (subtypes.any? || top_level) ? nil : "current-type"
      content_tag(:li, class: li_classes) do
        
        link_text = top_level ? types.first.full_name : types.first.family_name
        concat link_to(link_text, aircraft_family_path(types.first.slug))
        
        if subtypes.any?
          concat aircraft_type_tree(subtypes, false)
        elsif types.first.iata_aircraft_code.present?
          concat content_tag(:div, types.first.iata_aircraft_code, class: "supplemental-code")
        end

      end
    end

    return output
  end

  # Accepts an icon type and a raw BCBP value, and returns an image_tag for an
  # icon. Used to augment BCBP interpretations in a {BoardingPass} table, such
  # as on {FlightsController#show} or {FlightsController#show_boarding_pass}.
  #
  # @param type [:airline, :selectee] whether this icon should be for an
  #   airline logo, or for TSA PreCheck selectee status
  # @return [ActiveSupport::SafeBuffer, nil] an image tag for the appropriate
  #   icon
  # 
  # @see BoardingPass
  def display_icon(type, raw, interpretation=nil)
    return nil unless raw && type
    if type == :airline
      if raw =~ /^\d{3}$/
        airline = Airline.find_by(numeric_code: raw)
      else
        airline = Airline.find_by(iata_airline_code: raw.strip.upcase)
      end
      return nil unless airline
      return airline_icon(airline.slug, title: airline.airline_name)
    elsif type == :selectee
      return image_tag("tpc.png", title: interpretation, class: "airline-icon") if raw.to_i == 3
    end
    return nil
  end
  
  # Renders a radio button. Used to select between old or new values when
  # updating an existing {Flight} with a new {BoardingPass}.
  #
  # @param label [String] the name of the field for which data is being chosen,
  #   along with "current" or "updated" as appropriate
  # @param text_hash [Hash{Symbol => String}] a hash of any :code_block, :code,
  #   and :text associated with this field of the boarding pass
  # @return [ActiveSupport::SafeBuffer] HTML for a radio button and label
  # 
  # @see BoardingPass
  def format_radio_text(label, text_hash)
    label = content_tag(:span, label, class: "label")
    if text_hash.nil?
      text = content_tag(:span, "(blank)", class: "radio-empty")
    else
      text = Array.new
      text.push(content_tag(:code, sanitize(text_hash[:code_block].chars.each_slice(24).map(&:join).join("<br/>")), class: "radio-code-block")) if text_hash[:code_block]
      text.push(content_tag(:span, text_hash[:code], class: "radio-code")) if text_hash[:code]
      text.push(text_hash[:text]) if text_hash[:text]
      text = text.join("&emsp;")
    end
    return sanitize([label, text].join("<br/>"))
  end

  # Renders a star rating image based on a number between 0 and 5, inclusive.
  # Used for visually depicting the quality of different {TravelClass
  # TravelClasses}.
  # 
  # @param quality [Integer] A number of stars rating (0 through 5, inclusive)
  # @param inline [:left, :right, :both, :nil] Defines whether the image is
  #   inline to the left of text, to the right of text, in between text, or not
  #   inline. Used to determine margin styles.
  # @return [ActiveSupport::SafeBuffer] an image_tag for a star rating
  def quality_stars(quality, inline: nil)
    quality = quality.to_i
    quality = 0 if quality < 0
    quality = 5 if quality > 5
    classes = %w(star-rating)
    inline_classes = {left: "icon-left", right: "icon-right", both: "icon-between-text"}
    classes.push(inline_classes[inline]) if inline_classes[inline]
    return image_tag("stars/#{quality}.svg", title: "#{quality} out of 5 stars", alt: "#{quality} out of 5 stars", class: classes.join(" "))
  end
end
