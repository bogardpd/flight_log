# Defines helper methods for {Route} views.
module RoutesHelper

  # Converts an array of airport codes into a string of monospace-formatted
  # codes separated by two-way arrows.
  # 
  # @param codes [Array<String>] an array of airport codes
  # @return [ActiveSupport::SafeBuffer] a formatted route string
  def format_route(codes)
    return safe_join(codes.map{|airport| content_tag(:span, airport, class: "code-mono")}, " #{Route::ARROW_TWO_WAY_PLAINTEXT} ")
  end
  
end