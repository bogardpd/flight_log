# Defines helper methods for {Flight} views.
module FlightsHelper
  
  # Creates a nested list for an aircraft type and all of its parents.
  #
  # @param types [Array] the output of an {AircraftFamily#type_and_parent_types}
  #   call
  # @return [ActiveSupport::SafeBuffer, nil] a nested list of links to aircraft
  #   types
  def aircraft_type_tree(types, top_level=true)
    current = types.pop()

    ul_classes = ["aircraft-type-tree"]
    ul_classes.push("aircraft-type-tree-top") if top_level
    output = content_tag(:ul, class: ul_classes) do

      li_classes = (types.any? || top_level) ? nil : "current-type"
      content_tag(:li, class: li_classes) do

        link_text = top_level ? current.full_name : current.name
        concat link_to(link_text, aircraft_family_path(current.slug), title: "View flights on #{current.full_name} aircraft")

        if types.any?
          concat aircraft_type_tree(types, false)
        elsif current.iata_code.present?
          concat content_tag(:div, current.iata_code, class: "supplemental-code")
        end

      end
    end

    return output
  end

  # Accepts an icon type and an interpretation, and returns the text of the
  # interpretation, with an image_tag for an icon if appropriate. Used to
  # augment BCBP interpretations in a {BoardingPass} table, such as on
  # {FlightsController#show} or {FlightsController#show_boarding_pass}.
  #
  # @param icon_type [:airline, :airport, :selectee, :travel_class] whether this
  #   icon should be for an airline logo, airport country flag, TSA PreCheck
  #   selectee status, or travel class stars
  # @param interpretation [String, Hash, nil] The interpretation of what the raw
  #   value means. Can either be a string of the interpretation, or a hash with
  #   the interpretation string under the text key, and a slug for an icon under
  #   the icon_slug key.
  # @return [ActiveSupport::SafeBuffer, nil] interpretation text, with an an
  #   image tag for an icon if appropriate.
  #
  # @see BoardingPass
  def display_bcbp_interpretation(icon_type, interpretation)
    if interpretation.is_a?(Hash)
      icon_slug = interpretation[:icon_slug]
      interpretation = interpretation[:text]
    else
      icon_slug = nil
    end
    if icon_type
      icon = display_bcbp_icon(icon_type, interpretation, icon_slug)
      return interpretation unless icon
      return sanitize(interpretation) + content_tag(:div, icon, class: "interpreted-icon")
    else
      return interpretation
    end
  end

  # Accepts an icon type, interpretation, and icon slug, and returns an
  # image_tag for an icon.
  #
  # @param icon_type [:airline, :airport, :selectee, :travel_class] whether this
  #   icon should be for an airline logo, airport country flag, TSA PreCheck
  #   selectee status, or travel class stars
  # @param interpretation [String] The interpretation of what the raw
  # @param icon_slug [String] A unique identifier for an instance of this type
  #   of icon. (For example, an airline slug used to find an airline icon's
  #   filename.)
  # @return [ActiveSupport::SafeBuffer, nil] an image tag for the appropriate
  #   icon
  # 
  # @see #display_bcbp_interpretation
  def display_bcbp_icon(icon_type, interpretation, icon_slug)
    return nil unless icon_slug

    case icon_type
    when :airline
      return airline_icon(icon_slug, title: interpretation)
    when :airport
      return country_flag_icon(icon_slug)
    when :selectee
      if icon_slug == "LLLL"
        return image_tag("tpc.png", title: interpretation, class: "airline-icon")
      else
        return nil
      end
    when :travel_class
      return quality_stars(icon_slug)
    else
      return nil
    end
    return nil
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
