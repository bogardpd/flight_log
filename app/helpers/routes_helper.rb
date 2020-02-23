# Defines helper methods for {Route} views.
module RoutesHelper

  # Converts an array of airport codes into a string of monospace-formatted
  # codes separated by two-way arrows.
  # 
  # @param codes [Array<String>] an array of airport codes
  # @return [Object] a formatted route string
  def format_route(codes)
    return safe_join(codes.map{|airport| content_tag(:span, airport, class: "code-mono")}, " #{Route::ARROW_TWO_WAY_PLAINTEXT} ")
  end

  # Converts an array of airport codes and an array of airport cities into a
  # string of airport code abbr tags with city titles.
  #
  # @param codes [Array<String>] an array of airport codes
  # @param cities [Array<String>] an array of city names
  # @return [Object] an HTML-formatted route string
  def format_route_with_abbr(codes, cities)
    return safe_join([content_tag(:abbr, codes[0], title: cities[0]), Route::ARROW_TWO_WAY_PLAINTEXT, content_tag(:abbr, codes[1], title: cities[1])], " ")
  end
  
end