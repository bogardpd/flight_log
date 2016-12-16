class BoardingPass
  
  def initialize(boarding_pass_data)
    @raw_data = boarding_pass_data
    
    @bcbp_unique   = Hash.new
    @bcbp_repeated = Array.new
    
    @valid = false
    
    if @raw_data.present?
      @valid = true
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
    return @valid
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
  
  # Return data formatted into a string:
  def format_data(data)
    return data.to_s.gsub(' ','·')
  end
  
  # Return unique field values:
  
  def airline_designator_of_boarding_pass_issuer
    return nil unless @bcbp_unique['Airline Designator of Boarding Pass Issuer'].present?
    return @bcbp_unique['Airline Designator of Boarding Pass Issuer'].strip
  end
  
  def baggage_tag_license_plate_number
    return nil unless @bcbp_unique['Baggage Tag License Plate Number'].present?
    return @bcbp_unique['Baggage Tag License Plate Number'].strip
  end
  
  def date_of_issue_of_boarding_pass
    bp_date = @bcbp_unique['Date of Issue of Boarding Pass']
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
  end
  
  def document_type
    case @bcbp_unique['Document Type']
    when "B"
      return "Boarding pass"
    when "I"
      return "Itinerary receipt"
    else
      return nil
    end
  end
  
  def electronic_ticket
    return @bcbp_unique['Electronic Ticket Indicator'] == "E" ? "Yes" : "No"
  end
  
  def format_version
    return "IATA BCBP #{@bcbp_unique['Format Code']} Format Version #{@bcbp_unique['Version Number']}"
  end
  
  def number_of_legs_encoded
    return @raw_data[1].to_i
  end
  
  def passenger_description
    case @bcbp_unique['Passenger Description']
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
    return @bcbp_unique['Passenger Name']
  end
  
  def security
    return @bcbp_unique['Security']
  end
  
  def source_of_boarding_pass_issuance
    case @bcbp_unique['Source of Boarding Pass Issuance']
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
    case @bcbp_unique['Source of Check-In']
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
    return @bcbp_repeated[leg]['Airline Numeric Code']
  end
  
  def leg_check_in_sequence_number(leg)
    return @bcbp_repeated[leg]['Check-In Sequence Number'].to_i
  end
  
  def leg_compartment_code(leg)
    return @bcbp_repeated[leg]['Compartment Code']
  end
  
  def leg_date_of_flight(leg)
    bp_date = @bcbp_repeated[leg]['Date of Flight']
    return nil unless bp_date.present?
    day = bp_date.to_i
    if @flight && @flight.departure_utc
      # If date of flight is known, use that year
      year = @flight.departure_utc.year
    elsif @bcbp_unique['Date of Issue of Boarding Pass'].present?
      # If date of issue is set, assume year is in last 10 years
      if @bcbp_unique['Date of Issue of Boarding Pass'].to_s[0].to_i > (Date.today.year)%10
        # Year is in last decade
        year = (Date.today.year/10 - 1) * 10 + @bcbp_unique['Date of Issue of Boarding Pass'].to_s[0].to_i
      else
        # Year is in this decade
        year = (Date.today.year/10) * 10 + @bcbp_unique['Date of Issue of Boarding Pass'].to_s[0].to_i
      end
    else
      # Use current year
      year = Date.today.year
    end
    
    return Date.ordinal(year, day)
  end
  
  def leg_document_form_serial_number(leg)
    return @bcbp_repeated[leg]['Document Form/Serial Number']
  end
  
  def leg_flight_number(leg)
    return nil unless @bcbp_repeated[leg]['Flight Number'].present?
    return @bcbp_repeated[leg]['Flight Number'].strip.to_i
  end
  
  def leg_for_individual_airline_use(leg)
    return @bcbp_repeated[leg]['For Individual Airline Use']
  end
  
  def leg_free_baggage_allowance(leg)
    return @bcbp_repeated[leg]['Free Baggage Allowance']
  end
  
  def leg_frequent_flier_airline_designator(leg)
    return nil unless @bcbp_repeated[leg]['Frequent Flier Airline Designator'].present?
    return @bcbp_repeated[leg]['Frequent Flier Airline Designator'].strip
  end
  
  def leg_frequent_flier_number(leg)
    return nil unless @bcbp_repeated[leg]['Frequent Flier Number'].present?
    return @bcbp_repeated[leg]['Frequent Flier Number'].strip
  end
  
  def leg_from_city_airport_code(leg)
    return @bcbp_repeated[leg]['From City Airport Code']
  end
  
  def leg_id_ad_indicator(leg)
    case @bcbp_repeated[leg]['ID/AD Indicator']
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
    case @bcbp_repeated[leg]['International Documentation Verification']
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
    return nil unless @bcbp_repeated[leg]['Marketing Carrier Designator'].present?
    return @bcbp_repeated[leg]['Marketing Carrier Designator'].strip
  end
  
  def leg_operating_carrier_designator(leg)
    return nil unless @bcbp_repeated[leg]['Operating Carrier Designator'].present?
    return @bcbp_repeated[leg]['Operating Carrier Designator'].strip
  end
  
  def leg_operating_carrier_pnr_code(leg)
    return nil unless @bcbp_repeated[leg]['Operating Carrier PNR Code'].present?
    return @bcbp_repeated[leg]['Operating Carrier PNR Code'].strip
  end
  
  def leg_passenger_status(leg)
    case @bcbp_repeated[leg]['Passenger Status']
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
    row = @bcbp_repeated[leg]['Seat Number'][0..2].to_i
    seat = @bcbp_repeated[leg]['Seat Number'][3]
    return "#{row}#{seat}"
  end
  
  def leg_selectee_indicator(leg)
    case @bcbp_repeated[leg]['Selectee Indicator']
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
    return @bcbp_repeated[leg]['To City Airport Code']
  end
  
  private
    
    # Create and return a hash of IATA Bar Coded Boarding Pass (BCBP) fields and data.
    def create_bcbp(data)
      bcbp = Hash.new
      
      # MANDATORY ITEMS
      
      # 1: Format Code
      bcbp['Format Code'] = data[0]
      
      # 5: Number of Legs Encoded
      bcbp['Number of Legs Encoded'] = data[1]
      @valid = false unless bcbp['Number of Legs Encoded'] =~ /^\d{1}$/
      
      # 11: Passenger Name
      bcbp['Passenger Name'] = data[2..21]
      
      # 253: Electronic Ticket Indicator
      bcbp['Electronic Ticket Indicator'] = data[22]
      i = 22
      
      (0..number_of_legs_encoded-1).each_with_index do |leg, index|
        leg_data = Hash.new
        
        # 7: Operating Carrier PNR Code
        leg_data['Operating Carrier PNR Code'] = data[(i+1)..(i+=7)]
        
        # 26: From City Airport Code
        leg_data['From City Airport Code'] = data[(i+1)..(i+=3)]
        @valid = false unless leg_data['From City Airport Code'] =~ /^[A-Z]{3}$/
        
        # 38: To City Airport Code
        leg_data['To City Airport Code'] = data[(i+1)..(i+=3)]
        @valid = false unless leg_data['To City Airport Code'] =~ /^[A-Z]{3}$/
        
        # 42: Operating Carrier Designator
        leg_data['Operating Carrier Designator'] = data[(i+1)..(i+=3)]
        
        # 43: Flight Number
        leg_data['Flight Number'] = data[(i+1)..(i+=5)]
        @valid = false unless leg_data['Flight Number'] =~ /^\d{4}[A-Z ]{1}$/
        
        # 46: Date of Flight
        leg_data['Date of Flight'] = data[(i+1)..(i+=3)]
        @valid = false unless leg_data['Date of Flight'] =~ /^\d{3}$/
        
        # 71: Compartment Code
        leg_data['Compartment Code'] = data[(i+1)..(i+=1)]
        @valid = false unless leg_data['Compartment Code'] =~ /^[A-Z]{1}$/
        
        # 104: Seat Number
        leg_data['Seat Number'] = data[(i+1)..(i+=4)]
        @valid = false unless leg_data['Seat Number'] =~ /^\d{3}[A-Z]{1}$/
        
        # 107: Check-In Sequence Number
        leg_data['Check-In Sequence Number'] = data[(i+1)..(i+=5)]
        @valid = false unless leg_data['Check-In Sequence Number'] =~ /^[0-9 ]{4}[A-Z ]{1}$/
        
        # 113: Passenger Status
        leg_data['Passenger Status'] = data[(i+1)..(i+=1)]
        
        # 6: Field size of variable size field
        leg_data['Field size of variable size field'] = field_size = data[(i+1)..(i+=2)]
        @valid = false unless field_size =~ /^[0-9A-F]{2}$/
        field_size = "0x#{field_size}".to_i(16)
        
        if field_size > 0
          field_end = i + field_size
                    
          # CONDITIONAL ITEMS - UNIQUE
          if index == 0
            
            # 8: Beginning of Version Number
            bcbp['Beginning of Version Number'] = data[(i+1)..(i+=1)]
            @valid = false unless bcbp['Beginning of Version Number'] == ">"
            
            # 9: Version Number
            bcbp['Version Number'] = data[(i+1)..(i+=1)]
            
            # 10: Field size of following structured message - unique
            bcbp['Field size of following structured message - unique'] = data[(i+1)..(i+=2)]
            @valid = false unless bcbp['Field size of following structured message - unique'] =~ /^[0-9A-F]{2}$/
            unique_stop = i + bcbp['Field size of following structured message - unique'].to_i(16)
            
            # 15: Passenger Description
            bcbp['Passenger Description'] = i < unique_stop ? data[(i+1)..(i+=1 )] : nil
            
            # 12: Source of Check-In
            bcbp['Source of Check-In'] = i < unique_stop ? data[(i+1)..(i+=1 )] : nil
            
            # 14: Source of Boarding Pass Issuance
            bcbp['Source of Boarding Pass Issuance'] = i < unique_stop ? data[(i+1)..(i+=1 )] : nil
            
            # 22: Date of Issue of Boarding Pass (Julian Date)
            if i < unique_stop
              bcbp['Date of Issue of Boarding Pass'] = data[(i+1)..(i+=4 )]
              @valid = false unless bcbp['Date of Issue of Boarding Pass'] =~ /^[0-9 ]{4}$/
            else
              bcbp['Date of Issue of Boarding Pass'] = nil
            end
            
            # 16: Document Type
            bcbp['Document Type'] = i < unique_stop ? data[(i+1)..(i+=1 )] : nil
            
            # 21: Airline Designator of Boarding Pass Issuer
            bcbp['Airline Designator of Boarding Pass Issuer'] = i < unique_stop ? data[(i+1)..(i+=3 )] : nil
            
            # 23: Baggage Tag License Plate Number
            bcbp['Baggage Tag License Plate Number']  = i < unique_stop ? data[(i+1)..(i+=13)] : nil
            
          end
          
          # CONDITIONAL ITEMS - REPEATED
          
          # 17: Field size of following structured message - repeated
          leg_data['Field size of following structured message - repeated'] = data[(i+1)..(i+=2)]
          @valid = false unless leg_data['Field size of following structured message - repeated'] =~ /^[0-9A-F]{2}$/
          repeated_stop = i + leg_data['Field size of following structured message - repeated'].to_i(16)
          
          # 142: Airline Numeric Code
          if i < repeated_stop
            leg_data['Airline Numeric Code'] = data[(i+1)..(i+=3)]
            @valid = false unless leg_data['Airline Numeric Code'] =~ /^[0-9 ]{3}$/
          else
            leg_data['Airline Numeric Code'] = nil
          end
          
          # 143: Document Form/Serial Number
          if i < repeated_stop
            leg_data['Document Form/Serial Number'] = data[(i+1)..(i+=10)]
          else 
            leg_data['Document Form/Serial Number'] = nil
          end
          
          # 18: Selectee Indicator
          leg_data['Selectee Indicator'] = i < repeated_stop ? data[(i+1)..(i+=1)] : nil
          
          # 108: International Documentation Verification
          leg_data['International Documentation Verification'] = i < repeated_stop ? data[(i+1)..(i+=1)] : nil
          
          # 19: Marketing Carrier Designator
          leg_data['Marketing Carrier Designator'] = i < repeated_stop ? data[(i+1)..(i+=3 )] : nil
          
          # 20: Frequent Flier Airline Designator
          leg_data['Frequent Flier Airline Designator'] = i < repeated_stop ? data[(i+1)..(i+=3)] : nil
          
          # 236: Frequent Flier Number
          leg_data['Frequent Flier Number'] = i < repeated_stop ? data[(i+1)..(i+=16)] : nil
          
          # 89: ID/AD Indicator
          leg_data['ID/AD Indicator'] = i < repeated_stop ? data[(i+1)..(i+=1)] : nil
          
          # 118: Free Baggage Allowance
          leg_data['Free Baggage Allowance'] = i < repeated_stop ? data[(i+1)..(i+=3)] : nil
          
          # 4: For Individual Airline Use
          leg_data['For Individual Airline Use'] = data[(i+1)..field_end]
          
          i = field_end
          
        end
        
        @bcbp_repeated.push(leg_data)
      end
    
      bcbp['Security'] = data[(i+1)..(-1)]
      
      @bcbp_unique = bcbp
    
      return nil
      
      
    end
  
end