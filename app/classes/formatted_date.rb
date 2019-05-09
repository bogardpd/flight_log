# Defines a Date with specific formatting.
class FormattedDate < Date
  
  # Defines a standard date format string to use throughout the application.
  #
  # @return [String] a formatted date
  def standard_date
    return strftime("%-d %b %Y")
  end
  
end