class BoardingPass
  
  def initialize(boarding_pass_data)
    @data = boarding_pass_data
    
    if @data.present?
      @bcbp = create_bcbp(@data)
    else
      @bcbp = nil
    end
  end
  
  # Return a hash of IATA Bar Coded Boarding Pass (BCBP) fields and data.
  def bcbp_fields
    return @bcbp
  end
  
  # Return a hash of IATA BCBP fields for a particular leg. Leg number index
  # starts at 1.
  def leg_fields(leg_number)
    return nil if leg_number > number_of_legs_encoded || leg_number < 1
    # write me
  end
  
  def number_of_legs_encoded
    return @data[1].to_i
  end
  
  
  
  private
    
    # Create and return a hash of IATA Bar Coded Boarding Pass (BCBP) fields and data.
    def create_bcbp(data)
      bcbp = Hash.new
    
      # Mandatory Items
      bcbp['Format Code']                   = data[0]
      bcbp['Number of Legs Encoded']        = number_of_legs_encoded
      bcbp['Passenger Name']                = data[2..21].strip
      bcbp['Electronic Ticket Indicator']   = data[22]
      (1..number_of_legs_encoded).each do |leg|
        leg_data = Hash.new
      
      end
    
      bcbp['Operating Carrier PNR Code']    = data[23..29].strip
      bcbp['From City Airport Code']        = data[30..32]
      bcbp['To City Airport Code']          = data[33..35]
      bcbp['Operating Carrier Designator']  = data[36..38].strip
      bcbp['Flight Number']                 = data[39..43].strip.to_i
      bcbp['Date of Flight']                = data[44..46].strip.to_i #Parse to date
      bcbp['Compartment Code']              = data[47]
      bcbp['Seat Number']                   = data[48..51]
      bcbp['Check-In Sequence Number']      = data[52..56].strip.to_i
      bcbp['Passenger Status']              = data[57]
      bcbp['Field size of following variable size field'] = data[58..59]
    
      return bcbp
      
      
    end
  
end