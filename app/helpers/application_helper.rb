# Defines helper methods for the entire application.
module ApplicationHelper

  # Dimensions for a graph bar.
  GRAPH_BAR_DIMENSIONS = {width: 130, height: 30}
  # Y position for text rows. Keys are the number of text rows to draw, values
  # are arrays of y-positions in pixels.
  GRAPH_BAR_TEXT_Y = {1 => [21], 2 => [15, 27]}

  # Adds a link to the admin block.
  #
  # @param link [ActiveSupport::SafeBuffer] a link_to object
  # @return [nil]
  def add_admin_action(link)
    @admin_actions ||= Array.new
    @admin_actions.push(link)
  end

  # Adds a navigation breadcrumb.
  #
  # @param text [String] the link's text
  # @param path [Rails::Paths::Path] the link's path
  # @return [nil]
  def add_breadcrumb(text, path)
    @breadcrumbs ||= [["Home", root_path]]
    @breadcrumbs.push([text, path])
  end
  
  # Returns a title defined in a view's provide(:title) or content_for(:title),
  # or a default title if a title is not provided.
  #
  # @return [ActiveSupport::SafeBuffer] HTML for a <title> tag
  def title_tag
    base_title = "Paul Bogardʼs Flight Historian"
    return content_tag(:title, safe_join([content_for(:title), base_title].compact, " – "))
  end  
  
  # Returns a description <meta> tag with content provided by a view's
  # provide(:meta_description) or content_for(:meta_description), or a default
  # meta description if a meta description is not provied.
  #
  # @return [ActiveSupport::SafeBuffer] HTML for a <meta> tag
  def meta_description_tag
    default_description = "Paul Bogardʼs Flight Historian shows maps and tables for various breakdowns of Paulʼs flight history."
    description = content_for?(:meta_description) ? content_for(:meta_description) : default_description
    return content_tag(:meta, nil, name: "description", content: description)
  end
  
  # Formats the airport name portion of an city name. Anything contained
  # between a pair of parentheses is considered the airport name. Not all
  # cities will have airport names; airport names are only used for
  # disambiguation when a city has multiple airports.
  # 
  # @param city_airport_name [String] a city name which may or may not contain
  #   an airport name.
  # @return [ActiveSupport::SafeBuffer] A city name with any present airport
  #   name formatted.
  def format_airport_name(city_airport_name)
    return sanitize(city_airport_name.gsub(/\(.*\)/, '&ensp;<small class="airport-name">\0</small>').tr("()",""))
  end
  
  # Renders a message <div> containing an info box, success message, warning
  # message, or error message.
  #
  # @param type [:error, :warning, :success, :info] the type of message to
  #   provide. Used to determine the style of the message.
  # @param text [String] the message text
  # @param id [String] an ID for the message block
  # @return [ActiveSupport::SafeBuffer] a message <div>
  def render_message(type, text, id=nil)
    render partial: "layouts/message", locals: {message: {type: type, text: text, id: id}}
  end
  
  # Renders all messages (contained in \@messages) and flash messages for a
  # view, grouped by type.
  # 
  # @return [ActiveSupport::SafeBuffer] a number of message <div>s
  # @see #render_message
  def render_messages
    order = [:error, :warning, :success, :info]
    @messages ||= []
    @messages.concat(flash.map{|k,v| {type: k.to_sym, text: v}}) if flash
    @messages.sort_by!{|m| order.index(m[:type]) || order.length}
    render(partial: "layouts/message", collection: @messages)
  end
  
  # Renders an image containing an icon for an airline's logo.
  # 
  # @param slug [String] the unique slug for the airline whose logo is to be
  #   displayed
  # @param title [String] an optional title attribute for the logo image. If
  #   not provided, the airline's ICAO code will be used.
  # @param css_class [Array<String>] an optional set of CSS classes to apply to
  #   the logo image.
  # @return [ActiveSupport::SafeBuffer] an image_tag for an airline logo
  def airline_icon(slug, title: nil, css_class: nil)
    return image_tag("blank.png", class: "airline-icon") unless slug
    title ||= slug
    class_array = ["airline-icon"]
    class_array |= css_class if css_class
    return image_tag("#{ExternalImage::ROOT_PATH}/flights/airline-icons/#{slug}.png", title: title, alt: slug, class: class_array, onerror: "this.src='#{image_path("blank.png")}';this.onerror='';")
  end
  
  # Renders an image containing a country flag.
  # 
  # @param country [String] the country whose flag is to be displayed
  # @param title [String] an optional title attribute for the flag image. If
  #   not provided, the country's name will be used.
  # @return [ActiveSupport::SafeBuffer] an image_tag for a country flag
  def country_flag_icon(country, title: nil)
    return image_tag("blank.png", class: "country-flag-icon") unless country
    title ||= country
    return image_tag("#{ExternalImage::ROOT_PATH}/flights/country-flags/#{country.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9_-]/, "").squeeze("-")}.png", title: title, class: "country-flag-icon", onerror: "this.src='#{image_path("blank.png")}';this.onerror='';")
  end
  
  # Provides monospace formatting for a string. Generally used for formatting IATA and ICAO codes.
  #
  # @param code [ActiveSupport::SafeBuffer, String] the text to format
  # @return [ActiveSupport::SafeBuffer] HTML text formatted with a monospace font
  def code_mono(code)
    return nil unless code.present?
    return content_tag(:span, code, class: %w(code-mono))
  end

  # Provides HTML for a distance in miles and kilometers.
  #
  # @param distance_mi [Integer] the distance in statute miles
  # @param adjective [String] an adjective to prepend to the units
  # @param flight_link [Boolean] whether to include a link to the #flights
  #   anchor
  # @param paragraph [Boolean] whether to wrap the output in a paragraph tag
  # @return [ActiveSupport::SafeBuffer] HTML text
  def distance_block(distance_mi, adjective: nil, flight_link: false, paragraph: true)
    output = Array.new
    output.push(content_tag(:span, safe_join([NumberFormat.value(distance_mi), [adjective,"mile".pluralize(distance_mi)].compact.join(" ")], " "), class: "distance-primary"))
    output.push(content_tag(:span, "(#{NumberFormat.value(Distance::km(distance_mi))} km)", class: "distance-secondary"))
    if flight_link
      output.push(sanitize("&middot;"))
      output.push(link_to("See a list of these flights", "#flights"))
    end
    output = safe_join(output, " ")
    return paragraph ? content_tag(:p, output, class: "distance") : output
  end

  # Provides a table row containing a total {Flight Flights} count for the
  # table, and the percent of all flights that this count represents.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights}
  # @param extra_details [Array<ActiveSupport::SafeBuffer>] supplemental pieces
  #   of text to append to the total
  # @return [ActiveSupport::SafeBuffer] an HTML table row
  def flight_table_total_row(flights, extra_details=Array.new)
    flyer_flights = flyer.flights(current_user)
    output = Array.new
    output.push(pluralize(NumberFormat.value(flights.size), "flight"))
    if flyer_flights.any? && flights.size > 0
      percent = ((flights.size.to_f/flyer_flights.size.to_f)*1000).round/10.0
      output.push(content_tag(:span, "(#{percent}% of all flights)", class: "total-percent"))
    end
    output |= extra_details
    return content_tag(:tr) do
      content_tag(:td, safe_join(output.compact, " "), colspan: 4, id: "flight-total", class: "flightlog-total", "data-total": flights.size)
    end
  end

  # Provides a bar graph for a value. A single horizontal bar will be drawn with
  # the provided value as a percentage of the provided maximum, with the numeric
  # value centered on it. Used on numeric columns of tables to show the value of
  # the row relative to other rows (for example, Index Airlines will have a bar
  # for each airline in the table showing how many flights are on that airline).
  #
  # @param value [Integer] the value of this row
  # @param maximum [Integer] the maximum value of this column in the table. Used
  #   to set the 100% point of the bar.
  # @param is_distance [Boolean] whether or not the value is a distance in miles
  # @return [ActiveSupport::SafeBuffer] inline SVG for a graph
  def graph_bar(value, maximum, is_distance=false)
    return "" unless (value.present? && maximum > 0)
    bar_width = (value.to_f / maximum.to_f) * (GRAPH_BAR_DIMENSIONS[:width])

    svg = Nokogiri::HTML::DocumentFragment.parse("")
    Nokogiri::HTML::Builder.with(svg) do |xml|
      xml.svg(**GRAPH_BAR_DIMENSIONS, class: "graph-bar") do
        xml.rect(width: bar_width, height: GRAPH_BAR_DIMENSIONS[:height], class: "graph")
        if is_distance
          value_mi = NumberFormat.value(value)
          value_km = NumberFormat.value(Distance::km(value))
          xml.text_(value_mi, x: "30%", y: GRAPH_BAR_TEXT_Y[2][0], class: "graph-value graph-distance", "data-distance-mi": value)
          xml.text_("mile".pluralize(value), x: "30%", y: GRAPH_BAR_TEXT_Y[2][1], class: "graph-value graph-unit")
          xml.text_(value_km, x: "70%", y: GRAPH_BAR_TEXT_Y[2][0], class: "graph-value graph-distance")
          xml.text_("km", x: "70%", y: GRAPH_BAR_TEXT_Y[2][1], class: "graph-value graph-unit")
        else
          graph_text = NumberFormat.value(value)
          xml.text_(graph_text, x: "50%", y: GRAPH_BAR_TEXT_Y[1][0], class: "graph-value", "data-value": value)
        end
      end
    end
    
    return svg.to_xml.html_safe
  end
  
  # Renders a link which the user can click on to sort a table column. Used in
  # table headers. Includes an arrow showing the direction of the sort if the
  # table is already sorted by this column.
  #
  # In order for sort_link to work, {Table.sort_parse} must
  # have been called from the controller and stored in +@sort+.
  #
  # @param link_text [String] the text to use for the link
  # @param link_sort_category [Symbol] a symbol representing the name of the
  #   sortable column this link sorts. Compared to +@sort+ to determine if
  #   the table is already sorted by this column.
  # @param default_direction [:asc, :desc] the direction to sort this column,
  #   if a direction is not provided in the page URL parameters
  # @param page_anchor [String] the ID of the table to sort, so that the table
  #   remains in view when a sort link is clicked
  # @return [ActiveSupport::SafeBuffer] a link_to tag for sorting a table
  #   column.
  # @see Table.sort_parse
  def sort_link(link_text, link_sort_category, default_direction, page_anchor=nil)
    param_category, param_direction = @sort

    if param_category == link_sort_category
      if param_direction == :asc
        category_sort_direction_indicator = content_tag(:span, sanitize("&#x25B2;"), class: "sort-direction") # Up Triangle
      elsif param_direction == :desc
        category_sort_direction_indicator = content_tag(:span, sanitize("&#x25BC;"), class: "sort-direction") # Down Triangle
      end
    else
      category_sort_direction_indicator = nil
    end
    
    case default_direction
    when :asc
      sort_dir_string = ["desc","asc"]
      sort_direction = ["-",""]
    else
      sort_dir_string = ["asc","desc"]
      sort_direction = ["","-"]
    end
    if (param_category == link_sort_category && param_direction == default_direction)
      sort_polarity = sort_direction[0]
    else
      sort_polarity = sort_direction[1]
    end
    link_to(safe_join([link_text, category_sort_direction_indicator].compact, " "), url_for(region: params[:region], sort: sort_polarity.to_s + link_sort_category.to_s, anchor: page_anchor), class: "sort")
  end

  # Takes a tail number and prepends an image_tag for the appropriate country
  # flag to it.
  # 
  # @param tail_number [String] an aircraft tail number
  # @param show_blank_flag [Boolean] whether or not to show a blank placeholder
  #   flag image if the country cannot be determined
  # @return [ActiveSupport::SafeBuffer] an image_tag for a country flag, and
  #   the provided tail number
  # @see TailNumber.country
  # @see TailNumber.country_format
  def tail_number_with_country_flag(tail_number, show_blank_flag=true)
    country = TailNumber.country(tail_number)
    tail_format = TailNumber.format(tail_number)
    tail_link = link_to(tail_format, show_tail_path(tail_number), title: "View flights on tail number #{tail_format}")
    if country || show_blank_flag
      return country_flag_icon(country) + " " + tail_link
    else
      return tail_link
    end
  end
  
  
  # GREAT CIRCLE MAPPER HELPER FUNCTIONS
  
  # Creates HTML for a map with region select tabs.
  # 
  # @param map [Map] the map to show
  # @param selected_region [Array] the currently active region as an array of
  #   ICAO prefixes (e.g. ["K","PH"])
  # @option [String] :anchor (nil) a page anchor position for the region select links to link to
  # @return [ActiveSupport::SafeBuffer] HTML for a map with region select tabs
  # @see Map#gcmap_regions
  def gcmap_with_region_select(map, selected_region, anchor: nil)
    return content_tag(:div, id: anchor) do
      if map && map.gcmap_exists?
        concat gcmap_region_select_links(map, selected_region, anchor: anchor)
        concat map.gcmap
      else
        if selected_region.length > 0
          concat render_message(:warning, "Paul has taken no flights in #{"region".pluralize(selected_region.size)} #{selected_region.join(", ")}.")
        else
          concat render_message(:warning, "When flights have been added, you’ll see a map here.")
        end
      end
    end
  end
    
  # Creates region select tabs.
  # 
  # @param map [Map] the map to show
  # @param selected_region [Array] the currently active region as an array of
  #   ICAO prefixes (e.g. ["K","PH"])
  # @option [String] :anchor (nil) a page anchor position for the region select links to link to
  # @return [ActiveSupport::SafeBuffer] HTML region select tabs
  # @see Map#gcmap_regions
  def gcmap_region_select_links(map, selected_region, anchor: nil)
    region_hash = map.gcmap_regions(selected_region)
    tabs = Array.new
    
    region_hash.each do |region, values|
      if values[:selected]
        tabs.push(content_tag(:li, region, class: "selected"))
      else
        tabs.push(content_tag(:li, link_to(region, url_for(params.permit(:id, :sort, :region, :start_date, :end_date, :year, :fleet_number, :operator, :tail_number, :travel_class).merge(region: values[:icao].join("-"), anchor: anchor)))))
      end
    end
    
    if tabs.length > 1
      return content_tag(:div, content_tag(:ul, safe_join(tabs), class: "region-select"), class: "region-select")
    else
      return ""
    end
    
    
  end
  
end
