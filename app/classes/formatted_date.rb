class FormattedDate < Date
  
  def standard_date
    return strftime("%-d %b %Y")
  end
  
end