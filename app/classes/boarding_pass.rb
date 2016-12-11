class BoardingPass
  
  def initialize(boarding_pass_data)
    @raw_data = boarding_pass_data
    
    @bcbp_unique    = Hash.new
    @legs_repeated  = Hash.new
    
    if @raw_data.present?
      create_bcbp(@raw_data)
    end
  end
  
  # Return a hash of IATA Bar Coded Boarding Pass (BCBP) fields and data.
  def bcbp_fields
    return @bcbp_unique
  end
  
  # Return true if data is present.
  def has_data?
    return @raw_data.present?
  end
  
  # Return a hash of repeated per-leg fields, with leg numbers as the keys and
  # hashes of fields and data as the values.
  def legs
    return @legs_repeated
  end
  
  # Return the raw BCBP string.
  def raw
    return @raw_data
  end
  
  def number_of_legs_encoded
    return @raw_data[1].to_i
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
            unique_stop = i + bcbp['Field size of following structured message - unique'].to_i(16)
            
            bcbp['Passenger Description']             = i < unique_stop ? data[(i+1)..(i+=1)] : nil
            bcbp['Source of Check-In']                = i < unique_stop ? data[(i+1)..(i+=1)] : nil
            bcbp['Source of Boarding Pass Issuance']  = i < unique_stop ? data[(i+1)..(i+=1)] : nil
            bcbp['Date of Issue of Boarding Pass']    = i < unique_stop ? data[(i+1)..(i+=4)] : nil
            bcbp['Document Type']                     = i < unique_stop ? data[(i+1)..(i+=1)] : nil
            bcbp['Airline Designator of Boarding Pass Issuer'] = i < unique_stop ? data[(i+1)..(i+=3)] : nil
            bcbp['Baggage Tag License Plate Number']  = i < unique_stop ? data[(i+1)..(i+=13)] : nil
          end
          
          # Conditional Items - Repeated
          leg_data['Field size of following structured message - repeated'] = data[(i+1)..(i+=2)]
          repeated_stop = i + leg_data['Field size of following structured message - repeated'].to_i(16)
          
          leg_data['Airline Numeric Code']          = i < repeated_stop ? data[(i+1)..(i+=3)]  : nil
          leg_data['Document Form/Serial Number']   = i < repeated_stop ? data[(i+1)..(i+=10)] : nil
          leg_data['Selectee Indicator']            = i < repeated_stop ? data[(i+1)..(i+=1)]  : nil # 3: tsapre?
          leg_data['International Documentation Verification'] = 
                                                      i < repeated_stop ? data[(i+1)..(i+=1)]  : nil
          leg_data['Marketing Carrier Designator']  = i < repeated_stop ? data[(i+1)..(i+=3)]  : nil
          leg_data['Frequent Flier Airline Designator'] = 
                                                      i < repeated_stop ? data[(i+1)..(i+=3)]  : nil
          leg_data['Frequent Flier Number']         = i < repeated_stop ? data[(i+1)..(i+=16)] : nil
          leg_data['ID/AD Indicator']               = i < repeated_stop ? data[(i+1)..(i+=1)]  : nil
          leg_data['Free Baggage Allowance']        = i < repeated_stop ? data[(i+1)..(i+=3)]  : nil
          leg_data['For Individual Airline Use']    = data[(i+1)..field_end]
          
          i = field_end
          
        end
        
        @legs_repeated["Leg #{index+1}"] = leg_data
      end
    
      #bcbp['Beginning of Security Data']  = data[(i+1)..(i+=1)]
      #bcbp['Type of Security Data']       = data[(i+1)..(i+=1)]
      #bcbp['Length of Security Data']     = data[(i+1)..(i+=2)]
      bcbp['Security Data']               = data[(i+1)..(-1)]
      
      @bcbp_unique = bcbp
    
      return nil
      
      
    end
  
end