###############################################################################
# Defines a Boarding Pass based on IATA BarCoded Boarding Pass (BCBP) data.   #
###############################################################################

class BoardingPass
  include ActionView::Helpers::TextHelper
  
  def initialize(boarding_pass_data, flight: nil, interpretations: true)
    @raw_data = boarding_pass_data
    @flight = flight
    
    begin
      @airline_compartments = JSON.parse(File.read("app/assets/json/airline_compartments.json"))
    rescue
      @airline_compartments = nil
    end
    
    if @raw_data.present?
      @fields  = create_fields(determine_version(@raw_data))
      @control = create_control_points(@raw_data)
      @structured_data = build_structured_data(@control, @fields, interpretations)
    end
  end
  
  # Return false if any fields have valid equal to false or nil
  def is_valid?
    return false if @raw_data.blank?
    return extract_detail(:valid).reduce(:&)
  end
  
  def raw
    return @raw_data
  end
  
  def data
    return @structured_data
  end
  
  # Returns the most likely flight date given a known UTC Date
  def flight_date(known_date)
    candidate_years = *(known_date.year-1..known_date.year+1)
    flight_date = data.dig(:repeated, 0, :mandatory, 46, :raw).to_i
    return candidate_years.map{ |y|
      year_date = Date.gregorian_leap?(y) ? Date.ordinal(y,flight_date) : Date.ordinal(y,[365,flight_date].min)
      [year_date, (known_date - year_date).to_i.abs]
     }.min{|a,b| a.last <=> b.last }.first
  end
  
  # Returns a hash of form field values extracted from this barcode.
  def form_values(departure_utc_time = nil)
    return nil if data.nil?
    fields = Hash.new
    
    if departure_utc_time
      departure_date_local = flight_date(departure_utc_time.to_date)
      fields.store(:departure_date_local, departure_date_local)
    end
    
    origin_airport_iata = data.dig(:repeated, 0, :mandatory, 26, :raw)
    fields.store(:origin_airport_iata, origin_airport_iata)
    
    destination_airport_iata = data.dig(:repeated, 0, :mandatory, 38, :raw)
    fields.store(:destination_airport_iata, destination_airport_iata)
    
    airline_iata = data.dig(:repeated, 0, :mandatory, 42, :raw)&.strip
    if airline_iata.present?
      fields.store(:airline_iata, airline_iata)
      
      bp_issuer = data.dig(:unique, :conditional, 21, :raw)&.strip
      marketing_carrier = data.dig(:repeated, 0, :conditional, 19, :raw)&.strip
      if (bp_issuer.present? && airline_iata != bp_issuer)
        fields.store(:codeshare_airline_iata, bp_issuer)
      elsif (marketing_carrier.present? && airline_iata != marketing_carrier)
        fields.store(:codeshare_airline_iata, marketing_carrier)
      end
      begin
        airline_compartments = JSON.parse(File.read("app/assets/json/airline_compartments.json"))
        compartment_code = data.dig(:repeated, 0, :mandatory, 71, :raw)
        if compartment_code.present?
          travel_class = airline_compartments.dig(airline_iata, compartment_code, "name")
          class_code = TravelClass.get_class_id(travel_class)
          fields.store(:travel_class, class_code) if class_code
        end
      rescue Errno::ENOENT
      end
    end
    fields.store(:flight_number, data.dig(:repeated, 0, :mandatory, 43, :raw)&.strip&.gsub(/^0*/, ""))
    
    return fields
  end
  
  # Returns an array of a particular detail (:raw, :valid, etc.), in the order
  # that it would show up in the boarding pass raw data.
  def extract_detail(detail)
    return nil unless ordered_groups
    ordered_groups.map{|g| g[:fields].map{|k,v| v[detail.to_sym]}}.flatten
  end
    
  # Return an array of group titles and fields
  def ordered_groups
    output = Array.new
    set_group = proc{|title, fields|
      output.push({title: title, fields: fields})
    }
    return nil unless @control
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
  
  # Returns a hash of PNR
  def summary_fields
    output = Hash.new
    output.store(:pnr,     @structured_data.dig(:repeated, 0, :mandatory,  7, :raw))
    output.store(:airline, @structured_data.dig(:repeated, 0, :mandatory, 42, :raw))
    output.store(:flight,  @structured_data.dig(:repeated, 0, :mandatory, 43, :raw))
    output.store(:from,    @structured_data.dig(:repeated, 0, :mandatory, 26, :raw))
    output.store(:to,      @structured_data.dig(:repeated, 0, :mandatory, 38, :raw))
    output.inject(output){|h,(k,v)| h[k] = v.nil? ? nil : v.strip; h}
    return output
  end
  
  
  private
    
    # Determine the version number (or 0 if unknown):
    def determine_version(data)
      return 0 unless data.present?
      version = 0
      version_begin_loc = data.index(">")
      if version_begin_loc && data.length >= version_begin_loc + 2
        version += data[version_begin_loc + 1].to_i
      end
      return version
    end
    
    # Returns a hash of the control points (number of legs and variable field
    # sizes). Any groups which do not exist will be left out or set as nil, so
    # nil comparisons can be used to check if a group is present. If there is
    # invalid data, its starting position will be stored in an "invalid" key.
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
        invalid.call(len_um_rm) if data.index(">") != len_um_rm
        
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
        invalid.call(start_remainder) if (data.index("^") != start_remainder && data.index(">",len_um_rm+1) != start_remainder)
                  
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
        interpretation: :interpret_airline_code, type: :airline,
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
        interpretation: :interpret_pnr_code,
        validity: /^(?=^.{7}$)[A-Z0-9]+ *$/i})
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
        interpretation: :interpret_airline_code, type: :airline,
        validity: /^(?=^.{3}$) ?[A-Z0-9]{2,3} ?$/i})
      fields[ 43] = (prev = {description: "Flight Number",
        group: :rm, start: start.call(prev), length:  5,
        interpretation: :interpret_flight_number,
        validity: /^(?=^.{5}$) {0,3}\d{1,4} {0,3}[A-Z ]$/i})
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
        validity: /^(?=^.{5}$) {0,3}\d{1,4}[A-Z ]$/i})
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
        interpretation: :interpret_airline_code, type: :airline,
        validity: /^(\d{3}| {3})$/})
      fields[143] = (prev = {description: "Document Form/Serial Number",
        group: :rc, start: start.call(prev), length: 10,
        interpretation: :interpret_ticket_number, include_leg: true,
        validity: /^([A-Z0-9]{10}| {10})$/i})
      fields[ 18] = (prev = {description: "Selectee Indicator",
        group: :rc, start: start.call(prev), length:  1,
        interpretation: :interpret_selectee_indicator, type: :selectee})
      fields[108] = (prev = {description: "International Documentation Verification",
        group: :rc, start: start.call(prev), length:  1,
        interpretation: :interpret_international_documentation})
      fields[ 19] = (prev = {description: "Marketing Carrier Designator",
        group: :rc, start: start.call(prev), length:  3,
        interpretation: :interpret_airline_code, type: :airline,
        validity: v[:airline_designator_optional]})
      fields[ 20] = (prev = {description: "Frequent Flier Airline Designator",
        group: :rc, start: start.call(prev), length:  3,
        interpretation: :interpret_airline_code, type: :airline,
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
      if version >= 3 # Standard doesn't introduce this until v5, but UA appears to use this even with v3 passes
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
          validity: /^[\^>]$/})
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
    def build_structured_data(control, fields, interpretations)
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
              if interpretations && v[:interpretation]
                if v[:include_leg]
                  field.store(:interpretation, method(v[:interpretation]).call(raw, leg))
                else
                  field.store(:interpretation, method(v[:interpretation]).call(raw))
                end
                field.store(:type, v[:type]) if v[:type]
              end
            end
            group_fields.store(k, field)
          end
          
          # If extra data exists after all the fields, put it in an unknown field.
          if len_fields < len_group
            start_group = leg.nil? ? control.dig(group, :start) : control.dig(group, leg, :start)
            data = @raw_data[start_group+len_fields,len_group-len_fields]
            unk = unknown_field(data)
            group_fields.merge!(unk) if data.length > 0
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
      return {0 => {description: "Unknown Data", raw: raw, interpretation: "We don’t know what this data means."}}
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
        airline = Airline.where(numeric_code: raw) 
      else
        # Airline IATA code
        airline = Airline.where(iata_airline_code: raw.strip()) 
      end

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
        ticket_class = @airline_compartments[airline][code]["name"].capitalize
        ticket_details = @airline_compartments[airline][code]["details"]
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
          output += "(#{matching_dates.join(", ")})"
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