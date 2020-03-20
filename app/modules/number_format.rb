# Provides utilities for formatting numbers.
module NumberFormat

  # The string format for displaying dates (in strftime format).
  DATE_FORMAT = "%-d %b %Y"

  # The delimiter to use as a thousands separator.
  DELIMITER = ActionController::Base.helpers.sanitize("&nbsp;")
  
  # Formats a pair of decimal coordinates into a string pair of coordinates
  # with cardinal directions and 5 decimal places.
  # 
  # @param coordinates [Array<Number>] an array containing latitude and
  #   longitude, each in decimal degrees.
  # @return [ActiveSupport::SafeBuffer] a string pair of decimal degree
  #   coordinates with N/S and E/W hemispheres and 5 decimal places.
  def self.coordinates(coordinates)
    return ActionController::Base.helpers.sanitize("#{coordinates[0] < 0 ? "S" : "N"} #{"%.3f" % coordinates[0].abs}°, #{coordinates[1] < 0 ? "W" : "E"} #{"%.3f" % coordinates[1].abs}°")
  end

  # Formats a date.
  #
  # @param date [Date] a date.
  # @return [String] a formatted date string.
  def self.date(date)
    return "" if date.nil?
    return date.strftime(DATE_FORMAT)
  end

  # Formats a number by adding thousands separators.
  # 
  # @param number [Number] a number.
  # @return [String] a formatted number string.
  def self.value(number)
    return ActionController::Base.helpers.number_with_delimiter(number, delimiter: DELIMITER)
  end

end