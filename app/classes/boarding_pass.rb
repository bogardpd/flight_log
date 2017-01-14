class BoardingPass
  include ActionView::Helpers::TextHelper
  
  def initialize(boarding_pass_data, flight: nil)
    @raw_data = boarding_pass_data
    @flight = flight
    
    @bcbp_unique       = Hash.new
    @bcbp_repeated     = Array.new
    @raw_with_metadata = Array.new
    
    if @raw_data.present?
      create_bcbp(@raw_data)
    end
  end
  
  # Return BCBP version number, or -1 if version not present.
  def bcbp_version
    index = @raw_data.index(">")
    return @raw_data[index+1].to_i if index.present?
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
    return !(@raw_with_metadata.map{|h| h[:valid]}.include?(false || nil))
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
  # raw_with_metadata[i] = {
  #   description: 'x',
  #   raw:         'y',
  #   valid: [true|false]
  # }
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
  
  def baggage_tag_licence_plate_number
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
    return interpret_electronic_ticket_indicator(@bcbp_unique['253'])
  end
  
  def first_non_consecutive_baggage_tag_licence_number
    return nil unless @bcbp_unique['31'].present?
    return @bcbp_unique['31'].strip
  end
  
  def format_version
    output = "IATA BCBP #{@bcbp_unique['1']} Format"
    output += " Version #{@bcbp_unique['9']}" if @bcbp_unique['9']
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
  
  def second_non_consecutive_baggage_tag_licence_number
    return nil unless @bcbp_unique['32'].present?
    return @bcbp_unique['32'].strip
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
    return nil unless @bcbp_repeated[leg].present?
    return @bcbp_repeated[leg]['142']
  end
  
  def leg_check_in_sequence_number(leg)
    return nil unless @bcbp_repeated[leg].present?
    return @bcbp_repeated[leg]['107'].to_i
  end
  
  def leg_compartment_code(leg)
    return nil unless @bcbp_repeated[leg].present?
    return @bcbp_repeated[leg]['71']
  end
  
  def leg_date_of_flight(leg)
    return nil unless @bcbp_repeated[leg].present?
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
    
    rescue ArgumentError
      return nil
  end
  
  def leg_document_form_serial_number(leg)
    return nil unless @bcbp_repeated[leg].present?
    return @bcbp_repeated[leg]['143']
  end
  
  def leg_fast_track(leg)
    return nil unless @bcbp_repeated[leg].present?
    return @bcbp_repeated[leg]['254']
  end
  
  def leg_flight_number(leg)
    return nil unless @bcbp_repeated[leg].present? && @bcbp_repeated[leg]['43'].present?
    return @bcbp_repeated[leg]['43'].strip.to_i
  end
  
  def leg_for_individual_airline_use(leg)
    return nil unless @bcbp_repeated[leg].present?
    return @bcbp_repeated[leg]['4']
  end
  
  def leg_free_baggage_allowance(leg)
    return nil unless @bcbp_repeated[leg].present?
    free_raw = @bcbp_repeated[leg]['118']
    return nil unless free_raw.present?
    return pluralize(free_raw[0].to_i, "piece") if free_raw[0] =~ /\d/ && free_raw[1..2] == "PC" # "xPC" = x pieces
    return "#{free_raw[0..1].to_i} kg" if free_raw[0..1] =~ /\d{2}/ && free_raw[2] == "K"        # "xxK" = x kilos
    return "#{free_raw[0..1].to_i} lb" if free_raw[0..1] =~ /\d{2}/ && free_raw[2] == "L"        # "xxL" = x pounds
    return free_raw
  end
  
  def leg_frequent_flier_airline_designator(leg)
    return nil unless @bcbp_repeated[leg].present? && @bcbp_repeated[leg]['20'].present?
    return @bcbp_repeated[leg]['20'].strip
  end
  
  def leg_frequent_flier_number(leg)
    return nil unless @bcbp_repeated[leg].present? && @bcbp_repeated[leg]['236'].present?
    return @bcbp_repeated[leg]['236'].strip
  end
  
  def leg_from_city_airport_code(leg)
    return nil unless @bcbp_repeated[leg].present?
    return @bcbp_repeated[leg]['26']
  end
  
  def leg_id_ad_indicator(leg)
    return nil unless @bcbp_repeated[leg].present?
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
    return nil unless @bcbp_repeated[leg].present?
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
    return nil unless @bcbp_repeated[leg].present? && @bcbp_repeated[leg]['19'].present?
    return @bcbp_repeated[leg]['19'].strip
  end
  
  def leg_operating_carrier_designator(leg)
    return nil unless @bcbp_repeated[leg].present? && @bcbp_repeated[leg]['42'].present?
    return @bcbp_repeated[leg]['42'].strip
  end
  
  def leg_operating_carrier_pnr_code(leg)
    return nil unless @bcbp_repeated[leg].present? && @bcbp_repeated[leg]['7'].present?
    return @bcbp_repeated[leg]['7'].strip
  end
  
  def leg_passenger_status(leg)
    return nil unless @bcbp_repeated[leg].present?
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
    return nil unless @bcbp_repeated[leg].present?
    row = @bcbp_repeated[leg]['104'][0..2].to_i
    seat = @bcbp_repeated[leg]['104'][3]
    return "#{row}#{seat}"
  end
  
  def leg_selectee_indicator(leg)
    return nil unless @bcbp_repeated[leg].present?
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
    return nil unless @bcbp_repeated[leg].present?
    return @bcbp_repeated[leg]['38']
  end
  
  private
    
    # Create and return a hash of IATA Bar Coded Boarding Pass (BCBP) fields and data.
    def create_bcbp(data)
      bcbp = Hash.new
      
      # MANDATORY ITEMS
      
      # 1: Format Code
      bcbp['1'] = data[0]
      @raw_with_metadata.push({
        description: "Format Code",
        raw:         bcbp['1'],
        interpreted: "IATA BCBP Format #{bcbp['1']}",
        valid:       true
      })
      
      # 5: Number of Legs Encoded
      bcbp['5'] = data[1]
      @raw_with_metadata.push({
        description: "Number of Legs Encoded",
        raw:         bcbp['5'],
        interpreted: "This boarding pass contains #{pluralize(bcbp['5'], "flight leg")}",
        valid:       bcbp['5'] =~ /^\d{1}$/
      })
      
      # 11: Passenger Name
      bcbp['11'] = data[2..21]
      @raw_with_metadata.push({
        description: "Passenger Name",
        raw: bcbp['11'],
        valid: true
      })
      
      # 253: Electronic Ticket Indicator
      bcbp['253'] = data[22]
      @raw_with_metadata.push({
        description: "Electronic Ticket Indicator",
        raw:         bcbp['253'],
        interpreted: interpret_electronic_ticket_indicator(bcbp['253']),
        valid: true
      })
      
      i = 22
      
      (0..number_of_legs_encoded-1).each_with_index do |leg, index|
        leg_data = Hash.new
        
        # 7: Operating Carrier PNR Code
        leg_data['7'] = data[(i+1)..(i+=7)]
        @raw_with_metadata.push({
          description: format_leg(index, "Operating Carrier PNR Code"),
          raw:         leg_data['7'],
          valid:       true
        })
        
        # 26: From City Airport Code
        leg_data['26'] = data[(i+1)..(i+=3)]
        @raw_with_metadata.push({
          description: format_leg(index, "From City Airport Code"),
          raw:         leg_data['26'],
          interpreted: interpret_airport_code(leg_data['26']),
          valid:       leg_data['26'] =~ /^[A-Z]{3}$/
        })
        
        # 38: To City Airport Code
        leg_data['38'] = data[(i+1)..(i+=3)]
        @raw_with_metadata.push({
          description: format_leg(index, "To City Airport Code"),
          raw:         leg_data['38'],
          interpreted: interpret_airport_code(leg_data['38']),
          valid:       leg_data['38'] =~ /^[A-Z]{3}$/
        })
        
        # 42: Operating Carrier Designator
        leg_data['42'] = data[(i+1)..(i+=3)]
        @raw_with_metadata.push({
          description: format_leg(index, "Operating Carrier Designator"),
          raw:         leg_data['42'],
          interpreted: interpret_airline_code(leg_data['42']),
          valid:       true
        })
        
        # 43: Flight Number
        leg_data['43'] = data[(i+1)..(i+=5)]
        @raw_with_metadata.push({
          description: format_leg(index, "Flight Number"),
          raw:         leg_data['43'],
          valid:       leg_data['43'] =~ /^[0-9 ]{4}[A-Z ]{1}$/
        })
        
        # 46: Date of Flight
        leg_data['46'] = data[(i+1)..(i+=3)]
        @raw_with_metadata.push({
          description: format_leg(index, "Date of Flight (Julian Date)"),
          raw:         leg_data['46'],
          interpreted: interpret_julian_date(leg_data['46']),
          valid:       leg_data['46'] =~ /^\d{3}$/
        })
        
        # 71: Compartment Code
        leg_data['71'] = data[(i+1)..(i+=1)]
        @raw_with_metadata.push({
          description: format_leg(index, "Compartment Code"),
          raw:         leg_data['71'],
          valid:       leg_data['71'] =~ /^[A-Z]{1}$/
        })
        
        # 104: Seat Number
        leg_data['104'] = data[(i+1)..(i+=4)]
        @raw_with_metadata.push({
          description: format_leg(index, "Seat Number"),
          raw:         leg_data['104'],
          valid:       leg_data['104'] =~ /^\d{3}[A-Z]{1}$/
        })
        
        # 107: Check-In Sequence Number
        leg_data['107'] = data[(i+1)..(i+=5)]
        @raw_with_metadata.push({
          description: format_leg(index, "Check-In Sequence Number"),
          raw:         leg_data['107'],
          interpreted: interpret_checkin_sequence_number(leg_data['107']),
          valid:       leg_data['107'] =~ /^[0-9 ]{4}[A-Z ]{1}$/
        })
        
        # 113: Passenger Status
        leg_data['113'] = data[(i+1)..(i+=1)]
        @raw_with_metadata.push({
          description: format_leg(index, "Passenger Status"),
          raw:         leg_data['113'],
          valid:       true
        })
        
        # 6: Field size of variable size field
        leg_data['6'] = field_size = data[(i+1)..(i+=2)]
        @raw_with_metadata.push({
          description: format_leg(index, "Field size of variable size field (conditional + airline item 4)"),
          raw:         leg_data['6'],
          valid:       leg_data['6'] =~ /^[0-9A-Fa-f]{2}$/
        })
        field_size = "0x#{leg_data['6']}".to_i(16)
        
        if field_size > 0
          field_end = i + field_size
                    
          # CONDITIONAL ITEMS - UNIQUE
          if index == 0
            
            # 8: Beginning of Version Number
            bcbp['8'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({
              description: "Beginning of Version Number",
              raw:         bcbp['8'],
              valid: bcbp['8'] == ">"
            })
            
            # 9: Version Number
            bcbp['9'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({
              description: "Version Number",
              raw:         bcbp['9'],
              valid:       true
            })
            
            # 10: Field size of following structured message - unique
            bcbp['10'] = data[(i+1)..(i+=2)]
            @raw_with_metadata.push({
              description: "Field size of following structured messge - unique",
              raw:         bcbp['10'],
              valid:       bcbp['10'] =~ /^[0-9A-Fa-f]{2}$/
            })
            unique_stop = i + bcbp['10'].to_i(16)
            
            # 15: Passenger Description
            if i < unique_stop
              bcbp['15'] = data[(i+1)..(i+=1)]
              @raw_with_metadata.push({
                description: "Passenger Description",
                raw:         bcbp['15'],
                valid:       true
              })
            else
              bcbp['15'] = nil
            end
            
            # 12: Source of Check-In
            if i < unique_stop
              bcbp['12'] = data[(i+1)..(i+=1)]
              @raw_with_metadata.push({
                description: "Source of Check-In",
                raw:         bcbp['12'],
                valid:       true
              })
            else
              bcbp['12'] = nil
            end
            
            # 14: Source of Boarding Pass Issuance
            if i < unique_stop
              bcbp['14'] = data[(i+1)..(i+=1)]
              @raw_with_metadata.push({
                description: "Source of Boarding Pass Issuance",
                raw:         bcbp['14'],
                valid:       true
              })
            else
              bcbp['14'] = nil
            end
            
            # 22: Date of Issue of Boarding Pass (Julian Date)
            if i < unique_stop
              bcbp['22'] = data[(i+1)..(i+=4)]
              @raw_with_metadata.push({
                description: "Date of Issue of Boarding Pass (Julian Date)",
                raw:         bcbp['22'],
                interpreted: interpret_julian_date(bcbp['22']),
                valid:       bcbp['22'] =~ /^[0-9 ]{4}$/
              })
            else
              bcbp['22'] = nil
            end
            
            # 16: Document Type
            if i < unique_stop
              bcbp['16'] = data[(i+1)..(i+=1)]
              @raw_with_metadata.push({
                description: "Document Type",
                raw:         bcbp['16'],
                valid:       true
              })
            else
              bcbp['16'] = nil
            end
            
            # 21: Airline Designator of Boarding Pass Issuer
            if i < unique_stop
              bcbp['21'] = data[(i+1)..(i+=3)]
              @raw_with_metadata.push({
                description: "Airline Designator of Boarding Pass Issuer",
                raw:         bcbp['21'],
                interpreted: interpret_airline_code(bcbp['21']),
                valid:       true
              })
            else
              bcbp['21'] = nil
            end
            
            # 23: Baggage Tag Licence Plate Number
            if i < unique_stop
              bcbp['23'] = data[(i+1)..(i+=13)]
              @raw_with_metadata.push({
                description: "Baggage Tag Licence Plate Number(s)",
                raw:         bcbp['23'],
                valid:       true
              })
            else
              bcbp['23'] = nil
            end
            
            # 31: 1st Non-Consecutive Baggage Tag Licence Plate Number (Version 5+)
            if i < unique_stop && bcbp_version >= 5
              bcbp['31'] = data[(i+1)..(i+=13)]
              @raw_with_metadata.push({
                description: "1st Non-Consecutive Baggage Tag Licence Plate Number",
                raw:         bcbp['31'],
                valid:       true
              })
            else
              bcbp['31'] = nil
            end
            
            # 32: 2nd Non-Consecutive Baggage Tag Licence Plate Number (Version 5+)
            if i < unique_stop && bcbp_version >= 5
              bcbp['32'] = data[(i+1)..(i+=13)]
              @raw_with_metadata.push({
                description: "2nd Non-Consecutive Baggage Tag Licence Plate Number",
                raw:         bcbp['32'],
                valid:       true
              })
            else
              bcbp['32'] = nil
            end
            
          end
          
          # CONDITIONAL ITEMS - REPEATED
          
          # 17: Field size of following structured message - repeated
          leg_data['17'] = data[(i+1)..(i+=2)]
          @raw_with_metadata.push({
            description: format_leg(index, "Field size of following structured message - repeated"),
            raw:         leg_data['17'],
            valid:       leg_data['17'] =~ /^[0-9A-Fa-f]{2}$/
          })
          repeated_stop = i + leg_data['17'].to_i(16)
          
          # 142: Airline Numeric Code
          if i < repeated_stop
            leg_data['142'] = data[(i+1)..(i+=3)]
            @raw_with_metadata.push({
              description: format_leg(index, "Airline Numeric Code"),
              raw:         leg_data['142'],
              valid:       leg_data['142'] =~ /^[0-9 ]{3}$/
            })
          else
            leg_data['142'] = nil
          end
          
          # 143: Document Form/Serial Number
          if i < repeated_stop
            leg_data['143'] = data[(i+1)..(i+=10)]
            @raw_with_metadata.push({
              description: format_leg(index, "Document Form/Serial Number"),
              raw:         leg_data['143'],
              valid:       true
            })
          else 
            leg_data['143'] = nil
          end
          
          # 18: Selectee Indicator
          if i < repeated_stop
            leg_data['18'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({
              description: format_leg(index, "Selectee Indicator"),
              raw:         leg_data['18'],
              valid:       true
            })
          else
            leg_data['18'] = nil
          end
          
          # 108: International Documentation Verification
          if i < repeated_stop
            leg_data['108'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({
              description: format_leg(index, "International Documentation Verification"),
              raw:         leg_data['108'],
              valid:       true
            })
          else
            leg_data['108'] = nil
          end
          
          # 19: Marketing Carrier Designator
          if i < repeated_stop
            leg_data['19'] = data[(i+1)..(i+=3)]
            @raw_with_metadata.push({
              description: format_leg(index, "Marketing Carrier Designator"),
              raw:         leg_data['19'],
              interpreted: interpret_airline_code(leg_data['19']),
              valid:       true
            })
          else
            leg_data['19'] = nil
          end
          
          # 20: Frequent Flier Airline Designator
          if i < repeated_stop
            leg_data['20'] = data[(i+1)..(i+=3)]
            @raw_with_metadata.push({
              description: format_leg(index, "Frequent Flier Airline Designator"),
              raw:         leg_data['20'],
              interpreted: interpret_airline_code(leg_data['20']),
              valid:       true
            })
          else
            leg_data['20'] = nil
          end
          
          # 236: Frequent Flier Number
          if i < repeated_stop
            leg_data['236'] = data[(i+1)..(i+=16)]
            @raw_with_metadata.push({
              description: format_leg(index, "Frequent Flier Number"),
              raw:         leg_data['236'],
              valid:       true
            })
          else
            leg_data['236'] = nil
          end
          
          # 89: ID/AD Indicator
          if i < repeated_stop
            leg_data['89'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({
              description: format_leg(index, "ID/AD Indicator"),
              raw:         leg_data['89'],
              valid:       true
            })
          else
            leg_data['89'] = nil
          end
          
          # 118: Free Baggage Allowance
          if i < repeated_stop
            leg_data['118'] = data[(i+1)..(i+=3)]
            @raw_with_metadata.push({
              description: format_leg(index, "Free Baggage Allowance"),
              raw:         leg_data['118'],
              valid:       true
            })
          else
            leg_data['118'] = nil
          end
          
          # 254: Fast Track (Version 5+)
          if i < repeated_stop && bcbp_version >= 5
            leg_data['254'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({
              description: format_leg(index, "Fast Track"),
              raw:         leg_data['254'],
              valid:       true
            })
          else
            leg_data['254'] = nil
          end
          
          # 4: For Individual Airline Use
          leg_data['4'] = data[(i+1)..field_end]
          @raw_with_metadata.push({
            description: format_leg(index, "For Individual Airline Use"),
            raw:         leg_data['4'],
            valid:       true
          })
          
          i = field_end
          
        end
        
        @bcbp_repeated.push(leg_data)
      end
    
      # 25, 28, 29, 30: Security
      bcbp['30'] = data[(i+1)..(-1)]
      @raw_with_metadata.push({
        description: "Security Data",
        raw:         bcbp['30'],
        valid:       true
      })
      
      @bcbp_unique = bcbp
      
      # Check for any whitespace except space in the raw data
      @raw_with_metadata.each do |field|
        field[:valid] = false if field[:raw] =~ /(?![ ])\s/
      end
    
      return nil
      
      
    end
    
    
    
      
    # Takes an index (zero-indexed) and returns a formatted string (one-indexed).
    def format_leg(index, description)
      return "[Leg #{index+1}] #{description}"
    end
    
    
    
###############################################################################
# Raw BCBP Interpreters                                                       #
###############################################################################
    
    def interpret_airline_code(raw)
      return nil unless raw.present?
      airline = Airline.where(iata_airline_code: raw.strip()) 
      if airline.length > 0
        return airline.first.airline_name
      else
        return nil
      end
    end
    
    def interpret_airport_code(raw)
      airport = Airport.where(iata_code: raw) 
      if airport.length > 0
        return airport.first.city
      else
        return nil
      end
    end
    
    def interpret_checkin_sequence_number(raw)
      return nil unless raw.present?
      return "#{raw.strip().to_i.ordinalize} person to check in for this flight"
    end
    
    def interpret_julian_date(raw)
      return nil unless raw.present?
      
      invalid_date_error = "(not a valid date)"
      
      # Given the last digit of a year and a day of the year, returns a
      # FormattedDate of the best estimate of the date of this boarding pass.
      estimate_boarding_pass_issue_date = lambda { |year_digit, day_of_year|
        # Assume date is up to 1 year in the future or 9 years in the past.
        expected_dates = (9.years.ago.beginning_of_day...1.year.from_now.beginning_of_day)
        year_this_decade = Date.today.year/10*10 + year_digit
        years_to_consider = [year_this_decade-10,year_this_decade,year_this_decade+10]
        years_to_consider.each do |y|
          begin
            this_date = FormattedDate.ordinal(y, day_of_year)
            if expected_dates.cover?(this_date)
              return this_date
            end
          rescue
          end
        end
        return nil
      }
        
      if raw =~ /^\d{3}$/
        # Julian date without year
        
        # Returns a string of an array of likely dates
        estimate_julian_date = lambda { |day_of_year|
          year = Date.today.year
          dates = Array.new
          if day_of_year == 366
            # Find closest leap year
            # Worst case is non-leap-year century (i.e. 2100) where closest
            # leap years are an 8 year gap (2096, 2104). We assume the travel
            # date can't be more than one year in the future, so we'll search
            # from 7 years ago to next year, and then use the most recent leap
            # year found.
            (year-7..year+1).each do |y|
              begin
                this_date = FormattedDate.ordinal(y, 366)
                dates.push(this_date.standard_date)
              rescue
              end
            end
            return "(#{dates.last})"
          else
            ((year-1)..(year+1)).each do |y|
              begin
                this_date = FormattedDate.ordinal(y, day_of_year)
                dates.push(this_date.standard_date)
              rescue
              end
            end
            return "(#{dates.join(', ')})" if dates.length > 0
          end
          return invalid_date_error
        }
        
        day_of_year = raw.to_i
        output = "#{day_of_year.ordinalize} day of the year "
        conditional_start = @raw_data.index(">")
                
        if @flight
          # Get the year from the flight
          year = @flight.departure_date.year
          output += "(#{FormattedDate.ordinal(year, day_of_year).standard_date})"
        
        elsif (conditional_start && @raw_data[conditional_start+2,2].to_i(16)>=7 && @raw_data[conditional_start+7,4] =~ /^\d{4}$/)
          # Boarding pass issue date field exists and is correct format, so get
          # date from boarding pass year. Assume flight occurs between boarding
          # pass date and one year from boarding pass date
          bp_year_digit  = @raw_data[conditional_start+7].to_i
          bp_day_of_year = @raw_data[conditional_start+8,3].to_i
          bp_date = estimate_boarding_pass_issue_date.call(bp_year_digit, bp_day_of_year)
          return "#{output}#{estimate_julian_date.call(day_of_year)}" unless bp_date.present?
          expected_dates = (bp_date.beginning_of_day...(bp_date + 1.year).beginning_of_day)
          [bp_date.year,bp_date.year+1].each do |y|
            begin
              this_date = FormattedDate.ordinal(y, day_of_year)
              if expected_dates.cover?(this_date)
                return "#{output}(#{this_date.standard_date})"
              end
            rescue
            end

          end
          return "#{output}#{estimate_julian_date.call(day_of_year)}"
          
        else
          # Assume current year
          return "#{output}#{estimate_julian_date.call(day_of_year)}"
          
        end
        return output
        
      elsif raw =~ /^\d{4}$/
        # Julian date with year
        
        year_digit = raw[0].to_i
        day_of_year = raw[1..3].to_i
        output = "#{day_of_year.ordinalize} day of a year ending in #{year_digit} "
        if @flight
          flight_date = @flight.departure_date
          # Assume boarding pass was issued on or up to one decade prior to flight date
          expected_dates = (flight_date-10.years+2.day...flight_date+1.day)
          year_this_decade = flight_date.year/10*10 + year_digit
          years_to_consider = [year_this_decade-10,year_this_decade]
          years_to_consider.each do |y|
            begin
              this_date = FormattedDate.ordinal(y, day_of_year)
              if expected_dates.cover?(this_date)
                return "#{output}(#{this_date.standard_date})"
              end
            rescue
            end
          end
        else
          bp_date = estimate_boarding_pass_issue_date.call(year_digit, day_of_year)
          return "#{output}(#{bp_date.standard_date})" if bp_date
        end
        return "#{output}#{invalid_date_error}"
      end
      
      return nil
    end
    
    def interpret_electronic_ticket_indicator(raw)
      return raw == "E" ? "Electronic ticket" : "Not an electronic ticket"
    end
    
    

  
end