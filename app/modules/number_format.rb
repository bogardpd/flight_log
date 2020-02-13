# Provides utilities for working with dates.
module NumberFormat

  # The string format for displaying dates (in strftime format).
  DATE_FORMAT = "%-d %b %Y"
  
  # Formats a pair of decimal coordinates into a string pair of coordinates
  # with cardinal directions and 5 decimal places.
  # 
  # @param coordinates [Array<Number>] an array containing latitude and
  #   longitude, each in decimal degrees.
  # @return [ActiveSupport::SafeBuffer] a string pair of decimal degree
  #   coordinates with N/S and E/W hemispheres and 5 decimal places.
  def self.coordinates(coordinates)
    return ActionController::Base.helpers.sanitize("#{"%.5f" % coordinates[0].abs}° #{coordinates[0] < 0 ? "S" : "N"}&ensp;#{"%.5f" % coordinates[1].abs}° #{coordinates[1] < 0 ? "W" : "E"}")
  end

  # Formats a date.
  #
  # @param date [Date] a date.
  # @return [String] a formatted date string.
  def self.date(date)
    return "" if date.nil?
    return date.strftime(DATE_FORMAT)
  end

end