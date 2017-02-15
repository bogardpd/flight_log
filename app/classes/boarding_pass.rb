class BoardingPass
  include ActionView::Helpers::TextHelper
  
#  LEN_UM = 23 # Length of Unique Mandatory fields
#  LEN_RM = 37 # Length of each set of Repeated Mandatory fields
  
  def initialize(boarding_pass_data, flight: nil)
    @raw_data = boarding_pass_data
    @flight = flight
    
    @bcbp_unique       = Hash.new
    @bcbp_repeated     = Array.new
    @raw_with_metadata = Array.new
    
    begin
      @airline_compartments = JSON.parse(File.read('app/assets/json/airline_compartments.json'))
    rescue
      @airline_compartments = nil
    end
    
    if @raw_data.present?
      create_bcbp(@raw_data)
    end
    
    # New control point creation
    if @raw_data.present?
      @fields  = create_fields(determine_version(@raw_data))
      @control = create_control_points(@raw_data)
      @structured_data = build_structured_data(@control, @fields)
    end
  end
  
  def data
    return @structured_data
  end
  
  # Return an array of group titles and fields
  def ordered_groups
    output = Array.new
    set_group = proc{|title, fields|
      output.push({title: title, fields: fields})
    }
    if @control[:um]
      set_group.call("Unique Mandatory", @structured_data.dig(:unique, :mandatory))
    end
    if @control.dig(:rm, 0)
      set_group.call("Repeated Mandatory (Leg 1)", @structured_data.dig(:repeated, 0, :mandatory))
    end
    if @control[:uc]
      set_group.call("Unique Conditional", @structured_data.dig(:unique, :conditional))
    end
    if @control.dig(:rc, 0)
      set_group.call("Repeated Conditional (Leg 1)", @structured_data.dig(:repeated, 0, :conditional))
    end
    if @control.dig(:ra, 0)
      set_group.call("Repeated Airline Use (Leg 1)", @structured_data.dig(:repeated, 0, :airline))
    end
    if @control[:legs] && @control[:legs] > 1
      (1..@control[:legs]-1).each do |leg|
        if @control.dig(:rm, leg)
          set_group.call("Repeated Mandatory (Leg #{leg+1})", @structured_data.dig(:repeated, leg, :mandatory))
        end
        if @control.dig(:rc, leg)
          set_group.call("Repeated Conditional (Leg #{leg+1})", @structured_data.dig(:repeated, leg, :conditional))
        end
        if @control.dig(:ra, leg)
          set_group.call("Repeated Airline Use (Leg #{leg+1})", @structured_data.dig(:repeated, leg, :airline))
        end
      end
    end
    if @control[:security]
      set_group.call("Security", @structured_data.dig(:unique, :security))
    end
    if @control[:unknown]
      set_group.call("Unknown", @structured_data[:unknown])
    end
    
    # Check that raw data presence and order in output matches raw input
    if output.map{|g| g[:fields].map{|k,v| v[:raw]}}.join == @raw_data
      return output
    else
      raw_output = Array.new
      raw_output.push({title: "Raw Data", fields: {0 => {description: "Raw", raw: @raw_data, interpretation: "Something went wrong and we couldn’t parse this data."}}})
      return raw_output
    end
  end
  
  
  # TO DELETE
  
  def test_output
    return @fields[29].present?
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
    
    # Determine the version number (or 0 if unknown):
    def determine_version(data)
      return 0 unless data.present?
      version = 0
      version_begin_loc = data.index('>')
      if version_begin_loc && data.length >= version_begin_loc + 2
        version += data[version_begin_loc + 1].to_i
      end
      return version
    end
    
    # Returns a hash of the control points (number of legs and variable field
    # sizes). Any groups which do not exist will be left out or set as nil, so
    # nil comparisons can be used to check if a group is present. If there is
    # invalid data, its starting position will be stored in an 'invalid' key.
    def create_control_points(data)
      len_um    = len_group(:um)
      len_rm    = len_group(:rm)
      len_um_rm = len_group(:um,:rm)
      
      control = Hash.new
      # Set the invalid field and return control points:
      invalid = proc{|location|
        control.store(:unknown, location)
        return control
      }
      # Get a hex field size and return a decimal if valid, or call invalid if not:
      get_field_size = proc{|location, length|
        hex = data[location,length]
        invalid.call(location+length) if hex !~ /^[0-9A-F]+$/i
        hex.to_i(16)
      }
      # Set conditional and airline control points:
      get_conditional_and_airline = proc{|start_cond, len_cond_airline|
        control[:rc].push({start: start_cond, length: len_field(17)}) # Store in case next line fails
        rc_field_size = get_field_size.call(start_cond,len_field(17))
        len_cond = rc_field_size + len_field(17)
        len_airline = len_cond_airline - len_cond
        invalid.call(start_cond+len_field(17)) if len_airline < 0
        control[:rc].last[:length] = len_cond
        control[:ra].push(len_airline == 0 ? nil : {start: start_cond + len_cond, length: len_airline})
      }
      
      if data.length < len_um_rm
        # Mandatory data is too short
        invalid.call(0)
      end
      
      # NUMBER OF LEGS:
      legs = data[@fields.dig(5,:start),@fields.dig(5,:length)]
      if legs !~ /^[1-9]+$/
        invalid.call(0)
      end
      control.store(:legs, legs.to_i)
      
      # Set up arrays:
      control.store(:rm, Array.new) # Repeated Mandatory start and length data
      control.store(:rc, Array.new) # Repeated Conditional start and length data
      control.store(:ra, Array.new) # Repeated Airline use start and length data
      
      # UNIQUE MANDATORY FIELDS:
      control.store(:um, {start: 0, length: len_um})
      
      # REPEATED MANDATORY FIELDS (Leg 0):
      control[:rm].push({start: len_um, length: len_rm})
      
      # UNIQUE CONDITIONAL FIELDS:
      len_uc_rc0_ra0 = get_field_size.call(len_um_rm-len_field(6), len_field(6))
      
      if len_uc_rc0_ra0 == 0 # No unique or repeated[0] conditional fields
        control.store(:uc, nil)
        control[:rc].push(nil)
        control[:ra].push(nil)
      else
        # Check if version ">" is in the correct position
        invalid.call(len_um_rm) if data.index('>') != len_um_rm
        
        invalid.call(len_um_rm) if len_uc_rc0_ra0 < len_field(8,9,10) # Check that field 10 is available
        control.store(:uc, {start: len_um_rm, length: len_field(8,9,10)}) # Store in case next line fails
        len_uc = get_field_size.call(len_um_rm+len_field(8,9), len_field(10)) + len_field(8,9,10)
        control[:uc][:length] = len_uc
        # Check if RC0 exists:
        if len_uc_rc0_ra0 >= control.dig(:uc,:length) + len_field(17)        
          start_rc0 = len_um_rm + control.dig(:uc,:length)
          get_conditional_and_airline.call(start_rc0, len_uc_rc0_ra0-control.dig(:uc,:length), control.dig(:uc,:length))
        else
          # RC0 does not exist
          control[:rc].push(nil)
          control[:ra].push(nil)
        end
        
      end
     
      # Build rc[1..n] array:
      start_leg = len_um_rm + len_uc_rc0_ra0
      if control[:legs] > 1
        (1..(control[:legs]-1)).each do |leg|
          # Check that RMx is long enough
          invalid.call(start_leg) if data.length < start_leg + len_rm
          
          # Store start and length of mandatory fields in rm array
          control[:rm].push({start: start_leg, length: len_rm})
          
          # Get size of conditional fields
          len_rc_ra = get_field_size.call(start_leg+len_rm-2, len_field(6)) # Length of repeated conditional plus airline use
          if len_rc_ra == 0
            # No conditional or airline fields for this leg
            control[:rc].push(nil)
            control[:ra].push(nil)
          else
            invalid.call(start_leg+len_rm-len_field(6)) if len_rc_ra < len_field(17)
            get_conditional_and_airline.call(start_leg+len_rm,len_rc_ra)
          end
          
          # Set next leg start
          start_leg += (len_rm + len_rc_ra)
        end
      
      end
      
      start_remainder = start_leg
      len_remainder = data.length - start_leg
      return control unless len_remainder > 0
      
      if @fields[29].nil?
        # Boarding pass version does not have a security length field, so
        # consider everything at the end of the pass to be security data.
        control.store(:security, {start: start_remainder, length: len_remainder})
      else
        # Boarding pass version does have specific security fields, so perform
        # security field validity checks.
        
        # Check if security "^" starts at correct spot
        invalid.call(start_remainder) if data.index('^') != start_remainder
                  
        control.store(:security, {start: start_remainder, length: len_field(25,28,29)}) # Store in case next line fails
        len_security_data  = get_field_size.call(start_remainder+len_field(25,28),len_field(29))
        len_security_total = len_field(25,28,29)+len_security_data
        
        # Check if enough security data exists
        invalid.call(start_remainder + len_field(25,28,29)) if len_security_total > len_remainder
        
        # Update security values
        control[:security] = {start: start_remainder, length: len_security_total}
        
        # Check if extra data exists after security
        invalid.call(start_remainder+len_security_total) if len_security_total < len_remainder
      end
        
      return control
    end

    # Returns a hash of possible fields. If a version is detected, only fields
    # available in that BCBP version will be included.
    def create_fields(version=0)
      version ||= 0
      fields = Hash.new
      
      start = proc{|prev| prev[:start]+prev[:length]}
      
      v = { # Reused validity regexps
        airline_designator_optional: /^( {3}|[A-Z0-9]{1} {2}|[A-Z0-9]{2} {1}|[A-Z0-9]{3})$/i,
        airport_code_alpha: /^[A-Z]{3}$/i,
        baggage_tag: /^(\d{13}| {13})$/,
        hex: /^[0-9A-F]{2}$/i
      }
      
      # Unique Mandatory (:um)
      prev = {start: 0, length: 0}
      fields[  1] = (prev = {description: "Format Code",
        group: :um, start: start.call(prev), length:  1,
        interpretation: :interpret_format_code})
      fields[  5] = (prev = {description: "Number of Legs Encoded",
        group: :um, start: start.call(prev), length:  1,
        validity: /^\d{1}$/})
      fields[ 11] = (prev = {description: "Passenger Name",
        group: :um, start: start.call(prev), length: 20})
      fields[253] = (prev = {description: "Electronic Ticket Indicator",
        group: :um, start: start.call(prev), length:  1,
        interpretation: :interpret_electronic_ticket_indicator})
        
      # Unique Conditional (:uc)
      prev = {start: 0, length: 0}
      fields[  8] = (prev = {description: "Beginning of Version Number",
        group: :uc, start: start.call(prev), length:  1,
        validity: /^>$/})
      fields[  9] = (prev = {description: "Version Number",
        group: :uc, start: start.call(prev), length:  1,
        interpretation: :interpret_version_number})
      fields[ 10] = (prev = {description: "Field Size of Following Structured Message - Unique",
        group: :uc, start: start.call(prev), length:  2,
        interpretation: :interpret_field_size,
        validity: v[:hex]})
      fields[ 15] = (prev = {description: "Passenger Description",
        group: :uc, start: start.call(prev), length:  1,
        interpretation: :interpret_passenger_description})
      fields[ 12] = (prev = {description: "Source of Check-In",
        group: :uc, start: start.call(prev), length:  1,
        interpretation: :interpret_source_of_checkin})
      fields[ 14] = (prev = {description: "Source of Boarding Pass Issuance",
        group: :uc, start: start.call(prev), length:  1,
        interpretation: :interpret_source_of_boarding_pass_issuance})
      fields[ 22] = (prev = {description: "Date of Issue of Boarding Pass",
        group: :uc, start: start.call(prev), length:  4,
        interpretation: :interpret_ordinal_date,
        validity: /^((\d[0-2]\d{2}|\d3[0-5]\d|\d36[0-6])| {4})$/})
      fields[ 16] = (prev = {description: "Document Type",
        group: :uc, start: start.call(prev), length:  1,
        interpretation: :interpret_document_type})
      fields[ 21] = (prev = {description: "Airline Designator of Boarding Pass Issuer",
        group: :uc, start: start.call(prev), length:  3,
        interpretation: :interpret_airline_code,
        validity: v[:airline_designator_optional]})
      fields[ 23] = (prev = {description: "Baggage Tag Licence Plate Number",
        group: :uc, start: start.call(prev), length: 13,
        interpretation: :interpret_baggage_tag,
        validity: v[:baggage_tag]})
      if version >= 4
        fields[ 31] = (prev = {description: "1st Non-Consecutive Baggage Tag Licence Plate Number",
          group: :uc, start: start.call(prev), length: 13,
          interpretation: :interpret_baggage_tag,
          validity: v[:baggage_tag]})
        fields[ 32] = (prev = {description: "2nd Non-Consecutive Baggage Tag Licence Plate Number",
          group: :uc, start: start.call(prev), length: 13,
          interpretation: :interpret_baggage_tag,
          validity: v[:baggage_tag]})
      end
      
      # Repeated Mandatory (:rm)
      prev = {start: 0, length: 0}
      fields[  7] = (prev = {description: "Operating Carrier PNR Code",
        group: :rm, start: start.call(prev), length:  7,
        interpretation: :interpret_pnr_code})
      fields[ 26] = (prev = {description: "From City Airport Code",
        group: :rm, start: start.call(prev), length:  3,
        interpretation: :interpret_airport_code,
        validity: v[:airport_code_alpha]})
      fields[ 38] = (prev = {description: "To City Airport Code",
        group: :rm, start: start.call(prev), length:  3,
        interpretation: :interpret_airport_code,
        validity: v[:airport_code_alpha]})
      fields[ 42] = (prev = {description: "Operating Carrier Designator",
        group: :rm, start: start.call(prev), length:  3,
        interpretation: :interpret_airline_code})
      fields[ 43] = (prev = {description: "Flight Number",
        group: :rm, start: start.call(prev), length:  5,
        interpretation: :interpret_flight_number,
        validity: /^\d{4}[A-Z ]$/i})
      fields[ 46] = (prev = {description: "Date of Flight",
        group: :rm, start: start.call(prev), length:  3,
        interpretation: :interpret_ordinal_date,
        validity: /^([0-2]\d{2}|3[0-5]\d|36[0-6])$/})
      fields[ 71] = (prev = {description: "Compartment Code",
        group: :rm, start: start.call(prev), length:  1,
        interpretation: :interpret_compartment_code, include_leg: true,
        validity: /^[A-Z]{1}$/i})
      fields[104] = (prev = {description: "Seat Number",
        group: :rm, start: start.call(prev), length:  4,
        interpretation: :interpret_seat_number,
        validity: /((^\d{3}[A-Z]$)|INF)/i})
      fields[107] = (prev = {description: "Check-In Sequence Number",
        group: :rm, start: start.call(prev), length:  5,
        interpretation: :interpret_checkin_sequence_number,
        validity: /^\d{4}[A-Z ]$/i})
      fields[113] = (prev = {description: "Passenger Status",
        group: :rm, start: start.call(prev), length:  1,
        interpretation: :interpret_passenger_status})
      fields[  6] = (prev = {description: "Field Size of Following Variable Size Field",
        group: :rm, start: start.call(prev), length:  2,
        interpretation: :interpret_field_size,
        validity: v[:hex]})
        
      # Repeated Conditional (:rc)
      prev = {start: 0, length: 0}
      fields[ 17] = (prev = {description: "Field Size of Following Structured Message - Repeated",
        group: :rc, start: start.call(prev), length:  2,
        interpretation: :interpret_field_size,
        validity: v[:hex]})
      fields[142] = (prev = {description: "Airline Numeric Code",
        group: :rc, start: start.call(prev), length:  3,
        interpretation: :interpret_airline_code,
        validity: /^(\d{3}| {3})$/})
      fields[143] = (prev = {description: "Document Form/Serial Number",
        group: :rc, start: start.call(prev), length: 10,
        interpretation: :interpret_ticket_number, include_leg: true,
        validity: /^([A-Z0-9]{10}| {10})$/i})
      fields[ 18] = (prev = {description: "Selectee Indicator",
        group: :rc, start: start.call(prev), length:  1,
        interpretation: :interpret_selectee_indicator})
      fields[108] = (prev = {description: "International Documentation Verification",
        group: :rc, start: start.call(prev), length:  1,
        interpretation: :interpret_international_documentation})
      fields[ 19] = (prev = {description: "Marketing Carrier Designator",
        group: :rc, start: start.call(prev), length:  3,
        interpretation: :interpret_airline_code,
        validity: v[:airline_designator_optional]})
      fields[ 20] = (prev = {description: "Frequent Flier Airline Designator",
        group: :rc, start: start.call(prev), length:  3,
        interpretation: :interpret_airline_code,
        validity: v[:airline_designator_optional]})
      fields[236] = (prev = {description: "Frequent Flier Number",
        group: :rc, start: start.call(prev), length: 16})
      fields[ 89] = (prev = {description: "ID/AD Indicator",
        group: :rc, start: start.call(prev), length:  1,
        interpretation: :interpret_id_ad_indicator})
      fields[118] = (prev = {description: "Free Baggage Allowance",
        group: :rc, start: start.call(prev), length:  3,
        interpretation: :interpret_free_baggage_allowance,
        validity: /^(\dPC|\d{2}[KL]| {3})$/i})
      if version >= 5
        fields[254] = (prev = {description: "Fast Track",
          group: :rc, start: start.call(prev), length:  1})
      end
        
      # Repeated Airline Use (:ra)
      prev = {start: 0, length: 0}
      fields[  4] = (prev = {description: "For Individual Airline Use",
        group: :ra, start: start.call(prev), length: nil})
        
      # Security (:security)
      prev = {start: 0, length: 0}
      if version >= 3
        fields[ 25] = (prev = {description: "Beginning of Security Data",
          group: :security, start: start.call(prev), length:   1,
          validity: /^\^$/})
        fields[ 28] = (prev = {description: "Type of Security Data",
          group: :security, start: start.call(prev), length:   1})
        fields[ 29] = (prev = {description: "Length of Security Data",
          group: :security, start: start.call(prev), length:   2,
          interpretation: :interpret_field_size,
          validity: v[:hex]})
      end
      fields[ 30] = (prev = {description: "Security Data",
        group: :security, start: start.call(prev), length: nil})
      
      return fields
    end
    
    # Accepts a field ID string, and an optional leg number (zero-indexed).
    # Leg number is ignored on unique fields, but needed for repeated fields.
    # Returns the raw string from the given field (and leg). The results of
    # create_control_points need to be saved to @control, and the raw
    # data to @raw_data.
    def get_raw(field_id, leg=nil)
      return nil unless (field_id.present? && @control.present? && @raw_data.present?)
      
      field = @fields[field_id]
      return nil unless field.present? # Handle invalid field ID
      
      group = field[:group]
      if [:rm, :rc, :ra].include?(group)
        # This is a repeated field
        return nil unless leg.present? && leg < @control[:legs]
        control = @control[group][leg]
      else
        # This is not a repeated field
        control = @control[group]
      end
      return nil unless control.present?
      start = control[:start] + field[:start]
      
      if field[:length].nil? || field[:start] + field[:length] > control[:length]
        # Field is variable length or field length extends past end of its group
        len = control[:length] - field[:start]
      else
        len = field[:length]
      end
      
      return @raw_data[start,len] if (!@control[:unknown] || @control[:unknown] >= (start + len))
      
      return nil
    end
    
    # Create a nested hash of fields and values.
    # unique
    #   mandatory
    #     field {field data}
    #   conditional
    #     field {field data}
    #   security
    #     field {field data}
    # repeated [
    #   mandatory
    #     field {field data}
    #   conditional
    #     field {field data}
    #   airline
    #     field {field data}
    # ]
    # unknown
    
    def build_structured_data(control, fields)
      populate_group = proc{|group, leg=nil|
        group_fields = Hash.new
        if control[group].present? && (leg.nil? || control.dig(group, leg).present?)
          
          len_fields = 0
          len_group = leg.nil? ? control.dig(group, :length) : control.dig(group, leg, :length)
          
          fields.select{|k,v| v[:group] == group}.each do |k, v|
            raw = get_raw(k, leg)
            next if raw.nil? || raw.length == 0
            
            len_fields += raw.length
            
            if fields.dig(k, :length) && raw.length < fields.dig(k, :length)
              # Field was shortened, which means that it extended past the end
              # of its group. Mark this field as unknown, and stop adding any
              # further fields to this group.
              group_fields.merge!(unknown_field(raw))
              break
            elsif len_fields > len_group
              # Field is past the end of the group, so stop adding fields to
              # this group.
              break
            end
            
            field = Hash.new
            field.store(:description, v[:description])
            field.store(:raw, raw)
            if v[:validity] && raw !~ v[:validity]
              field.store(:valid, false)
            else
              field.store(:valid, true)
              if v[:interpretation]
                if v[:include_leg]
                  field.store(:interpretation, method(v[:interpretation]).call(raw, leg))
                else
                  field.store(:interpretation, method(v[:interpretation]).call(raw))
                end
              end
            end
            group_fields.store(k, field)
          end
          
          # If extra data exists after all the fields, put it in an unknown field.
          if len_fields < len_group
            start_group = leg.nil? ? control.dig(group, :start) : control.dig(group, leg, :start)
            unk = unknown_field(@raw_data[start_group+len_fields,len_group-len_fields])
            group_fields.merge!(unk)
          end
        end
        
        group_fields
      }

      output = Hash.new
      if !control[:unknown] || control[:unknown] >= len_group(:um,:rm)
        # BUILD UNIQUE HASH
        unique = Hash.new
        um       = populate_group.call(:um)
        unique.store(:mandatory,   um      )
        uc       = populate_group.call(:uc)
        unique.store(:conditional, uc      ) if uc.any?
        security = populate_group.call(:security)
        unique.store(:security,    security) if security.any?
      
        # BUILD REPEATED ARRAY
        repeated = Array.new
        (0..control[:legs]-1).each do |leg|
          leg_hash = Hash.new
          rm = populate_group.call(:rm, leg)
          leg_hash.store(:mandatory,   rm)
          rc = populate_group.call(:rc, leg)
          leg_hash.store(:conditional, rc) if rc.any?
          ra = populate_group.call(:ra, leg)
          leg_hash.store(:airline,     ra) if ra.any?
          repeated.push(leg_hash)
        end
      
        # CREATE OUTPUT HASH
        output.store(:unique, unique)
        output.store(:repeated, repeated)
      end
      
      if @control[:unknown]
        output.store(:unknown, unknown_field(@raw_data[@control[:unknown]..-1]))
      end
      
      return output
    end
    
    # Returns the total length of all field ids listed in *args. Variable size
    # fields and undefined fields will be counted as zero length.
    def len_field(*args)
      args.map{|id| @fields.dig(id, :length) || 0}.reduce(0, :+)
    end
    
    # Returns the total length of all fields in all group symbols listed in
    # *args. Variable size fields and undefined fields will be counted as zero
    # length.
    def len_group(*args)
      args.map{|group|
        @fields.select{|k,v| v[:group] == group}.map{|k,v| v[:length] || 0}.reduce(0,:+)
      }.reduce(0,:+)
    end
    
    # Returns a field hash in the format {0 => {description: "Unknown", raw: raw, interpretation: "..."}}
    def unknown_field(raw)
      return {0 => {description: "Unknown Data", raw: raw, interpretation: "We don't know what this data means."}}
    end
    
    # Create and return a hash of IATA Bar Coded Boarding Pass (BCBP) fields and data.
    def create_bcbp(data)
      bcbp = Hash.new
      
      if data.length < 60
        # Mandatory data is too short
        return nil
      end
      
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
          interpreted: interpret_pnr_code(leg_data['7']),
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
          interpreted: interpret_flight_number(leg_data['43']),
          valid:       leg_data['43'] =~ /^[0-9 ]{4}[A-Z ]{1}$/
        })
        
        # 46: Date of Flight
        leg_data['46'] = data[(i+1)..(i+=3)]
        @raw_with_metadata.push({
          description: format_leg(index, "Date of Flight (Julian Date)"),
          raw:         leg_data['46'],
          interpreted: interpret_ordinal_date(leg_data['46']),
          valid:       leg_data['46'] =~ /^\d{3}$/
        })
        
        # 71: Compartment Code
        leg_data['71'] = data[(i+1)..(i+=1)]
        @raw_with_metadata.push({
          description: format_leg(index, "Compartment Code"),
          raw:         leg_data['71'],
          #interpreted: interpret_compartment_code(leg_data['71'], leg_data['42']),
          valid:       leg_data['71'] =~ /^[A-Z]{1}$/
        })
        
        # 104: Seat Number
        leg_data['104'] = data[(i+1)..(i+=4)]
        @raw_with_metadata.push({
          description: format_leg(index, "Seat Number"),
          raw:         leg_data['104'],
          interpreted: interpret_seat_number(leg_data['104']),
          valid:       leg_data['104'] =~ /(^\d{3}[A-Z]{1}$|INF)/
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
          interpreted: interpret_passenger_status(leg_data['113']),
          valid:       true
        })
        
        # 6: Field size of variable size field
        leg_data['6'] = field_size = data[(i+1)..(i+=2)]
        @raw_with_metadata.push({
          description: format_leg(index, "Field size of variable size field (conditional + airline item 4)"),
          raw:         leg_data['6'],
          interpreted: interpret_field_size(leg_data['6']),
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
              valid:       bcbp['8'] == ">"
            })
            
            # 9: Version Number
            bcbp['9'] = data[(i+1)..(i+=1)]
            @raw_with_metadata.push({
              description: "Version Number",
              raw:         bcbp['9'],
              interpreted: (bcbp['9'].present? ? "IATA BCBP Format #{bcbp['1']} Version #{bcbp['9']}" : nil),
              valid:       true
            })
            
            # 10: Field size of following structured message - unique
            bcbp['10'] = data[(i+1)..(i+=2)]
            @raw_with_metadata.push({
              description: "Field size of following structured messge - unique",
              raw:         bcbp['10'],
              interpreted: interpret_field_size(bcbp['10']),
              valid:       bcbp['10'] =~ /^[0-9A-Fa-f]{2}$/
            })
            unique_stop = i + bcbp['10'].to_i(16)
            
            # 15: Passenger Description
            if i < unique_stop
              bcbp['15'] = data[(i+1)..(i+=1)]
              @raw_with_metadata.push({
                description: "Passenger Description",
                raw:         bcbp['15'],
                interpreted: interpret_passenger_description(bcbp['15']),
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
                interpreted: interpret_source_of_checkin(bcbp['12']),
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
                interpreted: interpret_source_of_boarding_pass_issuance(bcbp['14']),
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
                interpreted: interpret_ordinal_date(bcbp['22']),
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
                interpreted: interpret_document_type(bcbp['16']),
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
                interpreted: interpret_baggage_tag(bcbp['23']),
                valid:       bcbp['23'] =~ /^( {13}|\d{13})/
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
                interpreted: interpret_baggage_tag(bcbp['31']),
                valid:       bcbp['31'] =~ /^( {13}|\d{13})/
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
                interpreted: interpret_baggage_tag(bcbp['32']),
                valid:       bcbp['32'] =~ /^( {13}|\d{13})/
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
            interpreted: interpret_field_size(leg_data['17']),
            valid:       leg_data['17'] =~ /^[0-9A-Fa-f]{2}$/
          })
          repeated_stop = i + leg_data['17'].to_i(16)
          
          # 142: Airline Numeric Code
          if i < repeated_stop
            leg_data['142'] = data[(i+1)..(i+=3)]
            @raw_with_metadata.push({
              description: format_leg(index, "Airline Numeric Code"),
              raw:         leg_data['142'],
              interpreted: interpret_airline_code(leg_data['142']),
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
              interpreted: interpret_ticket_number(leg_data['143'], leg_data['142']),
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
              interpreted: interpret_selectee_indicator(leg_data['18']),
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
              interpreted: interpret_international_documentation(leg_data['108']),
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
              interpreted: interpret_id_ad_indicator(leg_data['89']),
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
              interpreted: interpret_free_baggage_allowance(leg_data['118']),
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
              interpreted: (leg_data['254'] == "Y" ? "Passenger is entitled to use a priority security or immigration lane" : nil),
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
# These methods all return strings of the interpretation of the raw value, or #
# return nil of an interpretation cannot be determined.                       #
###############################################################################
    
    def interpret_airline_code(raw)
      return nil unless raw.present?
      if raw =~ /^\d{3}$/
        # Airline numeric code
        return nil
      else
        airline = Airline.where(iata_airline_code: raw.strip()) 
        if airline.length > 0
          return airline.first.airline_name
        else
          return nil
        end
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
    
    def interpret_baggage_tag(raw)
      return nil unless raw.present?
      leading_digit = {"0": "interline", "1": "fall-back", "2": "interline rush"}[raw[0].to_sym]
      carrier_code_digits = raw[1..3]
      carrier_code = interpret_airline_code(carrier_code_digits)
      carrier_initial_tag_number = raw[4..9].to_i
      consecutive_tags = raw[10..12].to_i
      output = ""
      output += "#{leading_digit.capitalize} / " if leading_digit
      output += "#{carrier_code_digits} "
      output += "– #{carrier_code} " if carrier_code
      output += "/ #{pluralize(consecutive_tags+1, "bag")}: #"
      bag_tags = Array.new
      (0..consecutive_tags).each do |tag|
        bag_tags.push((carrier_initial_tag_number + tag).to_s.rjust(6, "0"))
      end
      output += bag_tags.join(", ")
      return output
    end
    
    def interpret_checkin_sequence_number(raw)
      return nil unless raw.present?
      return "#{raw.strip().to_i.ordinalize} person to check in for this flight"
    end
    
    def interpret_compartment_code(raw, leg)
      return nil unless raw.present? && leg.present?
      code = raw.upcase
      airline = get_raw(42, leg).strip
      begin
        ticket_class = @airline_compartments[airline][code]['name'].capitalize
        ticket_details = @airline_compartments[airline][code]['details']
      rescue
        ticket_class = code
      end
      output = "#{ticket_class} class ticket"
      output += " (#{ticket_details})" if ticket_details
      return output
    end
    
    def interpret_document_type(raw)
      map = {
        "B" => "Boarding pass",
        "I" => "Itinerary receipt"
      }
      return map[raw]
    end
    
    def interpret_electronic_ticket_indicator(raw)
      return raw == "E" ? "Electronic ticket" : "Not an electronic ticket"
    end
    
    def interpret_field_size(raw)
      return nil unless raw.present?
      return "#{raw.upcase} hexadecimal = #{raw.to_i(16)} decimal characters"
    end
    
    def interpret_flight_number(raw)
      return nil unless raw.present?
      return "Flight #{raw[0..3].to_i}#{raw[4].strip}"
    end
    
    def interpret_format_code(raw)
      map = {
        "M" => "IATA BCBP Format M"
      }
      return map[raw]
    end
    
    def interpret_free_baggage_allowance(raw)
      return nil unless raw.present?
      return pluralize(raw[0].to_i, "piece") if raw[0] =~ /\d/ && raw[1..2] == "PC" # "xPC" = x pieces
      return "#{raw[0..1].to_i} kg" if raw[0..1] =~ /\d{2}/ && raw[2] == "K"        # "xxK" = x kilos
      return "#{raw[0..1].to_i} lb" if raw[0..1] =~ /\d{2}/ && raw[2] == "L"        # "xxL" = x pounds
      return nil
    end
    
    def interpret_id_ad_indicator(raw)
      map = {
        "0" => "IDN1 positive space",
        "1" => "IDN2 space available",
        "2" => "IDB1 positive space",
        "3" => "IDB2 space available",
        "4" => "AD",
        "5" => "DG",
        "6" => "DM",
        "7" => "GE",
        "8" => "IG",
        "9" => "RG",
        "A" => "UD",
        "B" => "ID – industry discount not followed any classification",
        "C" => "IDFS1",
        "D" => "IDFS2",
        "E" => "IDR1",
        "F" => "IDR2"
      }
      return map[raw]
    end
    
    def interpret_international_documentation(raw)
      map = {
        "0" => "Travel document verification not required",
        "1" => "Travel document verification required",
        "2" => "Travel document verification performed"
      }
      return map[raw]
    end
    
    def interpret_ordinal_date(raw)
      return nil unless raw.present?
      
      error_text = "not a valid date"
      # Return an array of all dates in search_range that match day_of_year.
      # If specific_years are given, only return results in those years.
      find_matching_date = lambda { |search_range, day_of_year, specific_years: nil|
        likely_dates = Array.new
        specific_years ||= (search_range.begin.year..search_range.end.year)
        specific_years.each do |y|
          begin
            this_date = FormattedDate.ordinal(y, day_of_year)
            if search_range.cover?(this_date)
              likely_dates.push(this_date)
            end
          rescue
          end
        end
        return likely_dates
      }
      # Returns the most recent date matching day_of_year in a year ending in
      # year_digit. If flight_date is provided, search relative to that instead
      # of relative to today.
      estimate_issue_date = lambda { |year_digit, day_of_year, flight_date: nil|
        flight_date    ||= Date.today # if flight_date not set, set it to today
        search_range     = (flight_date-10.years+1.day..flight_date)
        year_this_decade = flight_date.year/10*10 + year_digit
        specific_years   = [year_this_decade-10,year_this_decade]
        likely_dates = find_matching_date.call(search_range, day_of_year, specific_years: specific_years)
        return likely_dates.last
      }
      
      if raw =~ /^\d{3}$/
        # Raw data format is 3 digits
        # This is a flight date
        day_of_year    = raw.to_i
        matching_dates = Array.new
        
        if day_of_year <= 366
          # day_of_year is valid
          if @flight
            # @flight data is available
            year           = @flight.departure_date.year
            range          = (Date.new(year,1,1)..Date.new(year,12,31))
            matching_dates = find_matching_date.call(range, day_of_year)
          else
            # @flight data is not available
            conditional_start = @raw_data.index(">")
            if (conditional_start && @raw_data[conditional_start+2,2].to_i(16)>=7 && @raw_data[conditional_start+7,4] =~ /^\d{4}$/)
              # Boarding pass issue date is present and valid
              bp_year_digit  = @raw_data[conditional_start+7].to_i
              bp_day_of_year = @raw_data[conditional_start+8,3].to_i
              bp_date        = estimate_issue_date.call(bp_year_digit, bp_day_of_year)
              if bp_date
                # Get first matching date within 1 year of boarding pass date
                # (if boarding pass date is year prior to leap year and has same
                # day of year as flight, two dates could potentially match)
                range          = (bp_date...bp_date+1.year)
                matching_dates = find_matching_date.call(range, day_of_year).first(1)
              end
            else
              # Boarding pass issue date is not available
              if day_of_year < 366
                # Find likely matching dates between 2 years ago and 1 year from now
                range          = (Date.today-2.years...Date.today+1.year)
                matching_dates = find_matching_date.call(range, day_of_year)
              else
                # Find most recent matching date in a leap year.
                # Largest gap between leap years is 8 years (centuries not
                # divisible by 400 are not leap years), so search between 31
                # Dec 7 years ago and 31 Dec 0 years ago (this year), and take
                # the most recent result.
                range = (Date.new(Date.today.year-7,12,31)..Date.new(Date.today.year,12,31))
                matching_dates = find_matching_date.call(range, day_of_year).last(1)
              end
            end
          end
        end
        
        output = "#{day_of_year.ordinalize} day of the year "
        if matching_dates.length > 0
          matching_dates.map!{|d| d.standard_date} # Format dates
          output += "(#{matching_dates.join(', ')})"
        else
          output += "(#{error_text})"
        end

        return output
        
      elsif raw =~ /^\d{4}$/
        # Raw data format is 4 digits
        # This is a boarding pass issue date
        year_digit    = raw[0].to_i
        day_of_year   = raw[1..3].to_i
        matching_date = nil
        
        if day_of_year <= 366
          # day_of_year is valid
          if @flight
            # @flight data is available
            matching_date = estimate_issue_date.call(year_digit, day_of_year, flight_date: @flight.departure_date)
          else
            # @flight data is not available
            matching_date = estimate_issue_date.call(year_digit, day_of_year)
          end
        end
        
        output = "#{day_of_year.ordinalize} day of a year ending in #{year_digit} " 
        output += matching_date ? "(#{matching_date.standard_date})" : "(#{error_text})"
        return output
        
      else
        # Raw data format is not 3 or 4 digits
        return nil
      end
    end
    
    def interpret_passenger_description(raw)
      map = {
        "0" => "Adult",
        "1" => "Male",
        "2" => "Female",
        "3" => "Child",
        "4" => "Infant",
        "5" => "No passenger (cabin baggage)",
        "6" => "Adult traveling with infant",
        "7" => "Unaccompanied Minor"
      }
      return map[raw]
    end
    
    def interpret_passenger_status(raw)
      map = {
        "0" => "Ticket issuance/passenger not checked in",
        "1" => "Ticket issuance/passenger checked in",
        "2" => "Baggage checked/passenger not checked in",
        "3" => "Baggage checked/passenger checked in",
        "4" => "Passenger passed security check",
        "5" => "Passenger passed gate exit (coupon used)",
        "6" => "Transit",
        "7" => "Standby",
        "8" => "Boarding pass revalidation done",
        "9" => "Original boarding line used at time of ticket issuance",
        "A" => "Up- or down-grading required"
      }
      return map[raw]
    end
    
    def interpret_pnr_code(raw)
      return nil unless raw.present?
      return "Passenger Name Record/record locator: #{raw.strip}"
    end
    
    def interpret_seat_number(raw)
      return nil unless raw.present?
      return "Infant seat" if raw =~ /INF/
      return "Seat #{raw[0..2].to_i}#{raw[3].strip}"
    end
    
    def interpret_selectee_indicator(raw)
      map = {
        "0" => "Not selectee",
        "1" => "SSSS (Secondary Security Screening Selectee)",
        "3" => "LLLL (TSA PreCheck)"
      }
      return map[raw]
    end
    
    def interpret_source_of_boarding_pass_issuance(raw)
      map = {
        "W" => "Web printed",
        "K" => "Airport kiosk printed",
        "X" => "Transfer kiosk printed",
        "R" => "Remote or off site kiosk printed",
        "M" => "Mobile device printed",
        "O" => "Airport agent printed",
        "T" => "Town agent printed",
        "V" => "Third party vendor printed",
        " " => "Unable to support"
      }
      return map[raw]
    end
  
    def interpret_source_of_checkin(raw)
      map = {
        "W" => "Web",
        "K" => "Airport kiosk",
        "R" => "Remote or off site kiosk",
        "M" => "Mobile device",
        "O" => "Airport agent",
        "T" => "Town agent",
        "V" => "Third party vendor"
      }
      return map[raw]
    end
    
    def interpret_ticket_number(raw, leg)
      return nil unless raw.present?
      airline_numeric = get_raw(142, leg)
      return "Ticket number: (#{airline_numeric}) #{raw}" if airline_numeric
      return "Ticket number: #{raw}"
    end
    
    def interpret_version_number(raw)
      return nil unless raw.present?
      return "IATA BCBP Version #{raw}"
    end
    
end