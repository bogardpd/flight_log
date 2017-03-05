###############################################################################
# Defines a boarding pass using Apple's PassKit Package (PKPass) format.      #
###############################################################################

class PKPass
  
  # Accepts a JSON string, and initializes the pass
  def initialize(pass)
    @json = pass
    @pass = JSON.parse(pass)
    @bcbp = BoardingPass.new(barcode)
  end
  
  # Returns the pass's barcode string
  def barcode
    return @pass.dig('barcode', 'message')
  end
  
  # Returns a hash of the fields which collectively define an IATA BarCoded
  # Boarding Pass (BCBP) unique pass: ordinal date of flight, operating carrier
  # code, flight number, check-in sequence number, and from city airport code.
  def bcbp_unique
    data = @bcbp.data
    return nil unless data
    unique = Array.new
    unique.push(data.dig(:repeated, 0, :mandatory,  46, :raw)) # Ordinal Date
    unique.push(data.dig(:repeated, 0, :mandatory,   7, :raw)) # PNR code
    unique.push(data.dig(:repeated, 0, :mandatory,  43, :raw)) # Flight Number
    unique.push(data.dig(:repeated, 0, :mandatory, 107, :raw)) # Check-in Sequence Number
    unique.push(data.dig(:repeated, 0, :mandatory,  26, :raw)) # From City Airport Code
    return unique.join('/').delete(' ')
  end
  
  # Returns a nested hash of pass data
  def hash
    return @pass
  end
  
  # Returns a name for the pass
  def identifier
    data = @bcbp.data
    return nil unless data
    date      = Date.parse(@pass.dig('relevantDate')).strftime("%d%b%Y")
    pnr       = data.dig(:repeated, 0, :mandatory,   7, :raw).strip
    airline   = data.dig(:repeated, 0, :mandatory,  42, :raw).strip
    flight    = data.dig(:repeated, 0, :mandatory,  43, :raw).strip
    from_city = data.dig(:repeated, 0, :mandatory,  26, :raw)
    to_city   = data.dig(:repeated, 0, :mandatory,  38, :raw)
    return "#{pnr} #{date} #{airline}#{flight} #{from_city}-#{to_city}"
  end
  
  # Returns the pass's raw JSON string
  def json
    return @json
  end
  
  # Returns the pass's serial number
  def serial_number
    return @pass.dig('serialNumber')
  end
  
end