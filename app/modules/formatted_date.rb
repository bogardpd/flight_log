# Provides utilities for working with dates.
module FormattedDate

  # The string format for displaying dates (in strftime format).
  FORMAT = "%-d %b %Y"

  # Formats a date.
  #
  # @param date [Date] a date.
  # @return [String] a formatted date string.
  def self.str(date)
    return date.strftime(FormattedDate::FORMAT)
  end

end