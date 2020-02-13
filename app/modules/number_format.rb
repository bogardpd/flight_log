# Provides utilities for working with dates.
module NumberFormat

  # The string format for displaying dates (in strftime format).
  DATE_FORMAT = "%-d %b %Y"

  # Formats a date.
  #
  # @param date [Date] a date.
  # @return [String] a formatted date string.
  def self.date(date)
    return "" if date.nil?
    return date.strftime(NumberFormat::DATE_FORMAT)
  end

end