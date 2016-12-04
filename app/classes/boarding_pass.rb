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
      bcbp['Number of Legs Encoded']        = data[1]
      bcbp['Passenger Name']                = data[2..21]
      bcbp['Electronic Ticket Indicator']   = data[22]
      i = 22
      
      (1..number_of_legs_encoded).each_with_index do |leg, index|
        leg_data = Hash.new
        leg_data['Operating Carrier PNR Code']    = data[(i+1)..(i+=7)]
        leg_data['From City Airport Code']        = data[(i+1)..(i+=3)]
        leg_data['To City Airport Code']          = data[(i+1)..(i+=3)]
        leg_data['Operating Carrier Designator']  = data[(i+1)..(i+=3)]
        leg_data['Flight Number']                 = data[(i+1)..(i+=5)]
        leg_data['Date of Flight']                = data[(i+1)..(i+=3)]
        leg_data['Compartment Code']              = data[(i+1)..(i+=1)]
        leg_data['Seat Number']                   = data[(i+1)..(i+=4)]
        leg_data['Check-In Sequence Number']      = data[(i+1)..(i+=5)]
        leg_data['Passenger Status']              = data[(i+1)..(i+=1)]
        leg_data['Field size of following variable size field'] = field_size = data[(i+1)..(i+=2)]
        
        field_size = "0x#{field_size}".to_i(16)
        
        if field_size > 0
          field_end = i + field_size
                    
          # Conditional Items - Unique
          if index == 0
            bcbp['Beginning of Version Number']       = data[(i+1)..(i+=1)]
            bcbp['Version Number']                    = data[(i+1)..(i+=1)]
            bcbp['Field size of following structured message - unique'] = data[(i+1)..(i+=2)]
            bcbp['Passenger Description']             = data[(i+1)..(i+=1)]
            bcbp['Source of Check-In']                = data[(i+1)..(i+=1)]
            bcbp['Source of Boarding Pass Issuance']  = data[(i+1)..(i+=1)]
            bcbp['Date of Issue of Boarding Pass']    = data[(i+1)..(i+=4)]
            bcbp['Document Type']                     = data[(i+1)..(i+=1)]
            bcbp['Airline Designator of Boarding Pass Issuer'] = data[(i+1)..(i+=3)]
            bcbp['Baggage Tag License Plate Number']  = data[(i+1)..(i+=13)]
          end
          
          # Conditional Items - Repeated
          leg_data['Field size of following structured message - repeated'] = data[(i+1)..(i+=2)]
          leg_data['Airline Numeric Code']          = data[(i+1)..(i+=3)]
          leg_data['Document Form/Serial Number']   = data[(i+1)..(i+=10)]
          leg_data['Selectee Indicator']            = data[(i+1)..(i+=1)]
          leg_data['International Documentation Verification'] = data[(i+1)..(i+=1)]
          leg_data['Marketing Carrier Designator']  = data[(i+1)..(i+=3)]
          leg_data['Frequent Flier Airline Designator'] = data[(i+1)..(i+=3)]
          leg_data['Frequent Flier Number']         = data[(i+1)..(i+=16)]
          leg_data['ID/AD Indicator']               = data[(i+1)..(i+=1)]
          leg_data['Free Baggage Allowance']        = data[(i+1)..(i+=3)]
          leg_data['For Individual Airline Use']    = data[(i+1)..field_end]
          
          i = field_end
          
        end
        
        bcbp["Leg #{index+1}"] = leg_data
      end
    
      bcbp['Beginning of Security Data']  = data[(i+1)..(i+=1)]
      bcbp['Type of Security Data']       = data[(i+1)..(i+=1)]
      bcbp['Length of Security Data']     = data[(i+1)..(i+=2)]
      bcbp['Security Data']               = data[(i+1)..(-1)]
    
      return bcbp
      
      
    end
  
end