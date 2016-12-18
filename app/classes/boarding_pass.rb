class BoardingPass
  
  def initialize(boarding_pass_data)
    @raw_data = boarding_pass_data
    
    @bcbp_unique       = Hash.new
    @bcbp_repeated     = Array.new
    @raw_with_metadata = Array.new
    
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
  
  # Return true if data appears to be valid BCBP data.
  def is_valid?
    return false unless @raw_data.present?
    return !(@raw_with_metadata.map{|h| h[:valid]}.include?(false))
  end
  
  # Return a hash of repeated per-leg fields, with leg numbers as the keys and
  # hashes of fields and data as the values.
  def legs
    return @bcbp_repeated
  end
  
  # Return the raw BCBP string.
  def raw
    return @raw_data
  end
  
  # Return an array of BCBP data fields with the following format:
  # raw_with_metadata[i] = {raw: 'w', valid: [true|false]}
  # The array is in order so that concatenating all raw fields returns a string
  # identical to the raw_data string.
  def raw_with_metadata
    # Check that concatenated raw data matches @raw_data
    if @raw_with_metadata.map{|h| h[:raw]}.join('') == @raw_data
      return @raw_with_metadata
    else
      return nil
    end
  end
  
  # Return unique field values:
  
  def airline_designator_of_boarding_pass_issuer
    return nil unless @bcbp_unique['21'].present?
    return @bcbp_unique['21'].strip
  end
  
  def baggage_tag_license_plate_number
    return nil unless @bcbp_unique['23'].present?
    return @bcbp_unique['23'].strip
  end
  
  def date_of_issue_of_boarding_pass
    bp_date = @bcbp_unique['22']
    return nil unless bp_date.present?
    day = bp_date.to_s[1..3].to_i
    if @flight && @flight.departure_utc
      # If date of flight is known, use that year
      year = @flight.departure_utc.year
    else
      # If date of issue is set, assume year is in last 10 years
      if bp_date.to_s[0].to_i > (Date.today.year)%10
        # Year is in last decade
        year = (Date.today.year/10 - 1) * 10 + bp_date.to_s[0].to_i
      else
        # Year is in this decade
        year = (Date.today.year/10) * 10 + bp_date.to_s[0].to_i
      end

    end
    
    return Date.ordinal(year, day)
    rescue ArgumentError
      return nil
  end
  
  def document_type
    case @bcbp_unique['16']
    when "B"
      return "Boarding pass"
    when "I"
      return "Itinerary receipt"
    else
      return nil
    end
  end
  
  def electronic_ticket
    return @bcbp_unique['253'] == "E" ? "Yes" : "No"
  end
  
  def format_version
    output = "IATA BCBP #{@bcbp_unique['1']} Format"
    output += "Version #{@bcbp_unique['9']}" if @bcbp_unique['9']
    return output
  end
  
  def number_of_legs_encoded
    return @raw_data[1].to_i
  end
  
  def passenger_description
    case @bcbp_unique['15']
    when "0"
      return "Adult"
    when "1"
      return "Male"
    when "2"
      return "Female"
    when "3"
      return "Child"
    when "4"
      return "Infant"
    when "5"
      return "No passenger (cabin baggage)"
    when "6"
      return "Adult traveling with infant"
    when "7"
      return "Unaccompanied Minor"
    else
      return nil
    end 
  end
  
  def passenger_name
    return @bcbp_unique['11']
  end
  
  def security
    return @bcbp_unique['30']
  end
  
  def source_of_boarding_pass_issuance
    case @bcbp_unique['14']
    when "W"
      return "Web printed"
    when "K"
      return "Airport kiosk printed"
    when "X"
      return "Transfer kiosk printed"
    when "R"
      return "Remote or off site kiosk printed"
    when "M"
      return "Mobile device printed"
    when "O"
      return "Airport agent printed"
    when "T"
      return "Town agent printed"
    when "V"
      return "Third party vendor printed"
    when " "
      return "Unable to support"
    else
      return nil
    end
  end
  
  def source_of_check_in
    case @bcbp_unique['12']
    when "W"
      return "Web"
    when "K"
      return "Airport kiosk"
    when "R"
      return "Remote or off site kiosk"
    when "M"
      return "Mobile device"
    when "O"
      return "Airport agent"
    when "T"
      return "Town agent"
    when "V"
      return "Third party vendor"
    else
      return nil
    end
  end
  
  # Return repeated field values:
  
  def leg_airline_numeric_code(leg)
    return @bcbp_repeated[leg]['142']
  end
  
  def leg_check_in_sequence_number(leg)
    return @bcbp_repeated[leg]['107'].to_i
  end
  
  def leg_compartment_code(leg)
    return @bcbp_repeated[leg]['71']
  end
  
  def leg_date_of_flight(leg)
    bp_date = @bcbp_repeated[leg]['46']
    return nil unless bp_date.present?
    day = bp_date.to_i
    if @flight && @flight.departure_utc
      # If date of flight is known, use that year
      year = @flight.departure_utc.year
    elsif @bcbp_unique['22'].present?
      # If date of issue is set, assume year is in last 10 years
      if @bcbp_unique['22'].to_s[0].to_i > (Date.today.year)%10
        # Year is in last decade
        year = (Date.today.year/10 - 1) * 10 + @bcbp_unique['22'].to_s[0].to_i
      else
        # Year is in this decade
        year = (Date.today.year/10) * 10 + @bcbp_unique['22'].to_s[0].to_i
      end
    else
      # Use current year
      year = Date.today.year
    end
    
    return Date.ordinal(year, day)
  end
  
  def leg_document_form_serial_number(leg)
    return @bcbp_repeated[leg]['143']
  end
  
  def leg_flight_number(leg)
    return nil unless @bcbp_repeated[leg]['43'].present?
    return @bcbp_repeated[leg]['43'].strip.to_i
  end
  
  def leg_for_individual_airline_use(leg)
    return @bcbp_repeated[leg]['4']
  end
  
  def leg_free_baggage_allowance(leg)
    return @bcbp_repeated[leg]['118']
  end
  
  def leg_frequent_flier_airline_designator(leg)
    return nil unless @bcbp_repeated[leg]['20'].present?
    return @bcbp_repeated[leg]['20'].strip
  end
  
  def leg_frequent_flier_number(leg)
    return nil unless @bcbp_repeated[leg]['236'].present?
    return @bcbp_repeated[leg]['236'].strip
  end
  
  def leg_from_city_airport_code(leg)
    return @bcbp_repeated[leg]['26']
  end
  
  def leg_id_ad_indicator(leg)
    case @bcbp_repeated[leg]['89']
    when "0"
      return "IDN1 positive space"
    when "1"
      return "IDN2 space available"
    when "2"
      return "IDB1 positive space"
    when "3"
      return "IDB2 space available"
    when "4"
      return "AD"
    when "5"
      return "DG"
    when "6"
      return "DM"
    when "7"
      return "GE"
    when "8"
      return "IG"
    when "9"
      return "RG"
    when "A"
      return "UD"
    when "B"
      return "ID – industry discount not followed any classification"
    when "C"
      return "IDFS1"
    when "D"
      return "IDFS2"
    when "E"
      return "IDR1"
    when "F"
      return "IDR2"
    else
      return nil
    end
  end
  
  def leg_international_documentation_verification(leg)
    case @bcbp_repeated[leg]['108']
    when "0"
      return "Travel document verification not required"
    when "1"
      return "Travel document verification required"
    when "2"
      return "Travel document verification performed"
    else
      return nil
    end
  end
  
  def leg_marketing_carrier_designator(leg)
    return nil unless @bcbp_repeated[leg]['19'].present?
    return @bcbp_repeated[leg]['19'].strip
  end
  
  def leg_operating_carrier_designator(leg)
    return nil unless @bcbp_repeated[leg]['42'].present?
    return @bcbp_repeated[leg]['42'].strip
  end
  
  def leg_operating_carrier_pnr_code(leg)
    return nil unless @bcbp_repeated[leg]['7'].present?
    return @bcbp_repeated[leg]['7'].strip
  end
  
  def leg_passenger_status(leg)
    case @bcbp_repeated[leg]['113']
    when "0"
      return "Ticket issuance/passenger not checked in"
    when "1"
      return "Ticket issuance/passenger checked in"
    when "2"
      return "Baggage checked/passenger not checked in"
    when "3"
      return "Baggage checked/passenger checked in"
    when "4"
      return "Passenger passed security check"
    when "5"
      return "Passenger passed gate exit (coupon used)"
    when "6"
      return "Transit"
    when "7"
      return "Standby"
    when "8"
      return "Boarding pass revalidation done"
    when "9"
      return "Original boarding line used at time of ticket issuance"
    when "A"
      return "Up- or down-grading required"
    else
      return nil
    end
  end
  
  def leg_seat_number(leg)
    row = @bcbp_repeated[leg]['104'][0..2].to_i
    seat = @bcbp_repeated[leg]['104'][3]
    return "#{row}#{seat}"
  end
  
  def leg_selectee_indicator(leg)
    case @bcbp_repeated[leg]['18']
    when "0"
      return "Not selectee"
    when "1"
      return "SSSS"
    when "3"
      return "LLLL"
    else
      return nil
    end
  end
  
  def leg_to_city_airport_code(leg)
    return @bcbp_repeated[leg]['38']
  end
  
  private
    
    # Create and return a hash of IATA Bar Coded Boarding Pass (BCBP) fields and data.
    def create_bcbp(data)
      bcbp = Hash.new
      
      # MANDATORY ITEMS
      
      # 1: Format Code
      bcbp['1'] = data[0]
      @raw_with_metadata.push({raw: bcbp['1'], valid: true})
      
      # 5: Number of Legs Encoded
      bcbp['5'] = data[1]
      @raw_with_metadata.push({raw: bcbp['5'], valid: bcbp['5'] =~ /^\d{1}$/})
      
      # 11: Passenger Name
      bcbp['11'] = data[2..21]
      @raw_with_metadata.push({raw: bcbp['11'], valid: true})
      
      # 253: Electronic Ticket Indicator
      bcbp['253'] = data[22]
      @raw_with_metadata.push({raw: bcbp['253'], valid: true})
      
      i = 22
      
      (0..number_of_legs_encoded-1).each_with_index do |leg, index|
        leg_data = Hash.new
        
        # 7: Operating Carrier PNR Code
        leg_data['7'] = data[(i+1)..(i+=7)]
        @raw_with_metadata.push({raw: leg_data['7'], valid: true})
        
        # 26: From City Airport Code
        leg_data['26'] = data[(i+1)..(i+=3)]
        @raw_with_metadata.push({raw: leg_data['26'], valid: leg_data['26'] =~ /^[A-Z]{3}$/})
        
        # 38: To City Airport Code
        leg_data['38'] = data[(i+1)..(i+=3)]
        @raw_with_metadata.push({raw: leg_data['38'], valid: leg_data['38'] =~ /^[A-Z]{3}$/})
        
        # 42: Operating Carrier Designator
        leg_data['42'] = data[(i+1)..(i+=3)]
        @raw_with_metadata.push({raw: leg_data['42'], valid: true})
        
        # 43: Flight Number
        leg_data['43'] = data[(i+1)..(i+=5)]
        @raw_with_metadata.push({raw: leg_data['43'], valid: leg_data['43'] =~ /^\d{4}[A-Z ]{1}$/})
        
        # 46: Date of Flight
        leg_data['46'] = data[(i+1)..(i+=3)]
        @raw_with_metadata.push({raw: leg_data['46'], valid: leg_data['46'] =~ /^\d{3}$/})
        
        # 71: Compartment Code
        leg_data['71'] = data[(i+1)..(i+=1)]
        @raw_with_metadata.push({raw: leg_data['71'], valid: leg_data['71'] =~ /^[A-Z]{1}$/})
        
        # 104: Seat Number
        leg_data['104'] = data[(i+1)..(i+=4)]
        @raw_with_metadata.push({raw: leg_data['104'], valid: leg_data['104'] =~ /^\d{3}[A-Z]{1}$/})
        
        # 107: Check-In Sequence Number
        leg_data['107'] = data[(i+1)..(i+=5)]
        @raw_with_metadata.push({raw: leg_data['107'], valid: leg_data['107'] =~ /^[0-9 ]{4}[A-Z ]{1}$/})
        
        # 113: Passenger Status
        leg_data['113'] = data[(i+1)..(i+=1)]
        @raw_with_metadata.push({raw: leg_data['113'], valid: true})
        
        # 6: Field size of variable size field
        leg_data['6'] = field_size = data[(i+1)..(i+=2)]
        @raw_with_metadata.push({raw: leg_data['6'], valid: leg_data['6'] =~ /^[0-9A-Fa-f]{2}$/})
        field_size = "0x#{leg_data['6']}".to_i(16)
        
        if field_size > 0
          field_end = i + field_size
                    
          # CONDITIONAL ITEMS - UNIQUE
          if index == 0
            
            # 8: Beginning of Version Number
            bcbp['8'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({raw: bcbp['8'], valid: bcbp['8'] == ">"})
            
            # 9: Version Number
            bcbp['9'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({raw: bcbp['9'], valid: true})
            
            # 10: Field size of following structured message - unique
            bcbp['10'] = data[(i+1)..(i+=2)]
            @raw_with_metadata.push({raw: bcbp['10'], valid: bcbp['10'] =~ /^[0-9A-Fa-f]{2}$/})
            unique_stop = i + bcbp['10'].to_i(16)
            
            # 15: Passenger Description
            if i < unique_stop
              bcbp['15'] = data[(i+1)..(i+=1)]
              @raw_with_metadata.push({raw: bcbp['15'], valid: true})
            else
              bcbp['15'] = nil
            end
            
            # 12: Source of Check-In
            if i < unique_stop
              bcbp['12'] = data[(i+1)..(i+=1)]
              @raw_with_metadata.push({raw: bcbp['12'], valid: true})
            else
              bcbp['12'] = nil
            end
            
            # 14: Source of Boarding Pass Issuance
            if i < unique_stop
              bcbp['14'] = data[(i+1)..(i+=1)]
              @raw_with_metadata.push({raw: bcbp['14'], valid: true})
            else
              bcbp['14'] = nil
            end
            
            # 22: Date of Issue of Boarding Pass (Julian Date)
            if i < unique_stop
              bcbp['22'] = data[(i+1)..(i+=4)]
              @raw_with_metadata.push({raw: bcbp['22'], valid: bcbp['22'] =~ /^[0-9 ]{4}$/})
            else
              bcbp['22'] = nil
            end
            
            # 16: Document Type
            if i < unique_stop
              bcbp['16'] = data[(i+1)..(i+=1)]
              @raw_with_metadata.push({raw: bcbp['16'], valid: true})
            else
              bcbp['16'] = nil
            end
            
            # 21: Airline Designator of Boarding Pass Issuer
            if i < unique_stop
              bcbp['21'] = data[(i+1)..(i+=3)]
              @raw_with_metadata.push({raw: bcbp['21'], valid: true})
            else
              bcbp['21'] = nil
            end
            
            # 23: Baggage Tag License Plate Number
            if i < unique_stop
              bcbp['23'] = data[(i+1)..(i+=13)]
              @raw_with_metadata.push({raw: bcbp['23'], valid: true})
            else
              bcbp['23'] = nil
            end
            
          end
          
          # CONDITIONAL ITEMS - REPEATED
          
          # 17: Field size of following structured message - repeated
          leg_data['17'] = data[(i+1)..(i+=2)]
          @raw_with_metadata.push({raw: leg_data['17'], valid: leg_data['17'] =~ /^[0-9A-Fa-f]{2}$/})
          repeated_stop = i + leg_data['17'].to_i(16)
          
          # 142: Airline Numeric Code
          if i < repeated_stop
            leg_data['142'] = data[(i+1)..(i+=3)]
            @raw_with_metadata.push({raw: leg_data['142'], valid: leg_data['142'] =~ /^[0-9 ]{3}$/})
          else
            leg_data['142'] = nil
          end
          
          # 143: Document Form/Serial Number
          if i < repeated_stop
            leg_data['143'] = data[(i+1)..(i+=10)]
            @raw_with_metadata.push({raw: leg_data['143'], valid: true})
          else 
            leg_data['143'] = nil
          end
          
          # 18: Selectee Indicator
          if i < repeated_stop
            leg_data['18'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({raw: leg_data['18'], valid: true})
          else
            leg_data['18'] = nil
          end
          
          # 108: International Documentation Verification
          if i < repeated_stop
            leg_data['108'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({raw: leg_data['108'], valid: true})
          else
            leg_data['108'] = nil
          end
          
          # 19: Marketing Carrier Designator
          if i < repeated_stop
            leg_data['19'] = data[(i+1)..(i+=3)]
            @raw_with_metadata.push({raw: leg_data['19'], valid: true})
          else
            leg_data['19'] = nil
          end
          
          # 20: Frequent Flier Airline Designator
          if i < repeated_stop
            leg_data['20'] = data[(i+1)..(i+=3)]
            @raw_with_metadata.push({raw: leg_data['20'], valid: true}) 
          else
            leg_data['20'] = nil
          end
          
          # 236: Frequent Flier Number
          if i < repeated_stop
            leg_data['236'] = data[(i+1)..(i+=16)]
            @raw_with_metadata.push({raw: leg_data['236'], valid: true})
          else
            leg_data['236'] = nil
          end
          
          # 89: ID/AD Indicator
          if i < repeated_stop
            leg_data['89'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({raw: leg_data['89'], valid: true})
          else
            leg_data['89'] = nil
          end
          
          # 118: Free Baggage Allowance
          if i < repeated_stop
            leg_data['118'] = data[(i+1)..(i+=3)]
            @raw_with_metadata.push({raw: leg_data['118'], valid: true})
          else
            leg_data['118'] = nil
          end
          
          # 4: For Individual Airline Use
          leg_data['4'] = data[(i+1)..field_end]
          @raw_with_metadata.push({raw: leg_data['4'], valid: true})
          
          i = field_end
          
        end
        
        @bcbp_repeated.push(leg_data)
      end
    
      # 25, 28, 29, 30: Security
      bcbp['30'] = data[(i+1)..(-1)]
      @raw_with_metadata.push({raw: bcbp['30'], valid: true})
      
      @bcbp_unique = bcbp
      
      # Check for any whitespace except space in the raw data
      @raw_with_metadata.each do |field|
        field[:valid] = false if field[:raw] =~ /(?![ ])\s/
      end
    
      return nil
      
      
    end
  
end