# Provides utilities for interacting with tail numbers.
#
# Tail number uniqueness is considered case insensitive and insensitive to
# the presence or absence of dashes. However, tail numbers are nearly always
# capitalized, and most countries have either no dash in their tail numbers or
# a dash that's always in the same position in the tail number. Throughout this
# module, documentation will refer to formatted tail numbers and simplified
# tail numbers. A *formatted* tail number is a string with dashes in the
# appropriate place for the country (e.g. +VH-OQI+, +C-FGRY+, +N909EV+), and a
# *simplified* tail number is a string with all dashes removed (e.g. +VHOQI+,
# +CFGRY+, +N909EV+).
module TailNumber
 
  # Capitalizes a tail number and strips non-alphanumeric characters.
  # 
  # Tail number uniqueness is considered case insensitive and insensitive to
  # the presence or absence of dashes, so this method puts the tail number into
  # a standard simplified format for saving it into the database.
  #
  # @param tail_number [String] a tail number
  # @return [String] a simplified tail number
  # @example
  #   TailNumber.simplify("VH-OQI") #=> "VHOQI"
  def self.simplify(tail_number)
    return tail_number.upcase.gsub(/[^A-Z0-9]/,"")
  end
  
  # Returns the country associated with a given tail number.
  # 
  # @param tail_number [String] a formatted or simplified tail number
  # @return [String] a country name
  # @example
  #   TailNumber.country("N909EV") #=> "United States"
  def self.country(tail_number)
    return country_format(tail_number)[:country]
  end
  
  # Takes a tail number and adds dashes as appropriate.
  # 
  # @param tail_number [String] a simplified tail number
  # @return [String] a formatted tail number
  # @example
  #   TailNumber.format("CFGRY") #=> "C-FGRY"
  def self.format(tail_number)
    return country_format(tail_number)[:tail]
  end
  
  # Returns an array of tail numbers, {AircraftFamily} codes (ICAO preferred),
  # {AircraftFamily} manufacturers, {AircraftFamily} names, {Airline} names,
  # {Airline} slugs, and number of {Flight Flights} on that tail number, sorted
  # by number of flights descending.
  #
  # Used on various "index" and "show" views to generate a table of tail
  # numbers and their flight counts.
  #
  # @param flights [Array<Flight>] a collection of {Flight Flights} to
  #   calculate tail number flight counts for
  # @param sort_category [:tail, :flights, :aircraft, :airline] the category to
  #   sort the array by
  # @param sort_direction [:asc, :desc] the direction to sort the array
  # @return [Array<Hash>] details for each tail number flown
  def self.flight_table_data(flights, sort_category=nil, sort_direction=nil)
    tail_counts = flights.reorder(nil).where.not(tail_number: nil).group(:tail_number).count
    tail_details = flights.where.not(tail_number: nil).includes(:airline, :aircraft_family)
    return nil unless tail_details.any?
    counts = tail_details.map{|f| {f.tail_number => {
      airline_slug:  f.airline.slug,
      airline_name:  f.airline.airline_name,
      aircraft_code: f.aircraft_family&.icao_code || f.aircraft_family&.iata_code,
      manufacturer:  f.aircraft_family&.manufacturer,
      name:   f.aircraft_family&.name,
      departure_utc: f.departure_utc
    }}}
      .reduce{|a,b| a.merge(b){|k,oldval,newval| newval[:departure_utc] > oldval[:departure_utc] ? newval : oldval}}
      .merge(tail_counts){|k,oldval,newval| oldval.store(:count, newval); oldval}
      .map{|k,v| {
        tail_number:  k,
        count:        v[:count],
        country:      country(k),
        aircraft:     v[:aircraft_code] || "",
        airline_name: v[:airline_name] || "",
        airline_slug: v[:airline_slug] || "",
        manufacturer: v[:manufacturer],
        name:  v[:name]
      }}
      
    
    case sort_category
    when :tail
      counts.sort_by!{|tail| tail[:tail_number]}
      counts.reverse! if sort_direction == :desc
    when :flights
      sort_mult   = (sort_direction == :asc ? 1 : -1)
      counts.sort_by!{|tail| [sort_mult*tail[:count], tail[:tail_number]]}
    when :aircraft
      counts.sort_by!{|tail| [tail[:aircraft], tail[:airline_name]]}
      counts.reverse! if sort_direction == :desc
    when :airline
      counts.sort_by!{|tail| [tail[:airline_name], tail[:aircraft]]}
      counts.reverse! if sort_direction == :desc
    else
      counts.sort_by!{|tail| [-(tail[:count] || 0), tail[:tail_number] || ""]}
    end

    return counts
    
  end

  private

  # Defines countries and dash formats for various tail number regular
  # expressions. Used by other methods to determine a country name and/or a
  # dash position based on which regular expression a simplified tail number
  # matches.
  #
  # The dash position specifies the character position of a dash in a country's
  # tail number format (e.g. C-FGRY has a dash postion of 1, VH-OQI has a dash
  # position of 2). If the dash position is 0, then no dash is assumed (e.g.
  # N909EV).
  #
  # @return [Hash] tail number regexps as keys, country names and dash
  #   positions as values
  # @example
  #   TailNumber.countries[/^VH[A-Z]{3}$/] #=> {country: "Australia", dash: 2}
  # @see .simplify
  def self.countries
    tail_formats = {
      # Highest numbers of aircraft:
      /^N[1-9]((\d{0,4})|(\d{0,3}[A-HJ-NP-Z])|(\d{0,2}[A-HJ-NP-Z]{2}))$/ => {
        country: "United States",
        dash: 0 },
      /^B((1[5-9]\d{2})|([2-9]\d{3}))$/ => {
        country: "China",
        dash: 1 },
      /^C[FGI][A-Z]{3}$/ => {
        country: "Canada",
        dash: 1 },
      /^D(([A-CE-IK-O][A-Z]{3})|(\d{4}))$/ => {
        country: "Germany",
        dash: 1 },
      /^G[A-Z]{4}$/ => {
        country: "United Kingdom",
        dash: 1 },
      /^F[A-Z]{4}$/ => {
        country: "France",
        dash: 1 },
      /^JA((\d{4})|(\d{3}[A-Z])|(\d{2}[A-Z]{2})|(A\d{3}))$/ => {
        country: "Japan",
        dash: 0 },
      /^P[PRSTU][A-Z]{3}$/ => {
        country: "Brazil",
        dash: 2 },
      /^EC[A-WY][A-Z]{2}$/ => {
        country: "Spain",
        dash: 2 },
      /^VT[A-Z]{3}$/ => {
        country: "India",
        dash: 2 },
        
      # Other countries:
      /^VH[A-Z]{3}$/ => {
        country: "Australia",
        dash: 2 },
      /^OE([A-LV-X][A-Z]{2}|[0-59]\d{3})$/ => {
        country: "Austria",
        dash: 2 },
      /^OY[A-Z]{3}$/ => {
        country: "Denmark",
        dash: 2 },
      /^OH(([A-Z]{3})|(G|U)?(\d{2}[1-9]|\d[1-9]\d|[1-9]\d{2}))$/ => {
        country: "Finland",
        dash: 2 },
      /^9G[A-Z]{3}$/ => {
        country: "Ghana",
        dash: 2 },
      /^SX[A-Z]{3}$/ => {
        country: "Greece",
        dash: 2 },
      /^B[HKL][A-Z]{2}$/ => {
        country: "Hong Kong",
        dash: 1 },
      /^TF(([A-Z]{3})|([1-9]\d{2}))$/ => {
        country: "Iceland",
        dash: 2 },
      /^4X[A-Z]{3}$/ => {
        country: "Israel",
        dash: 2 },
      /^JY[A-Z]{3}$/ => {
        country: "Jordan",
        dash: 2 },
      /^9M[A-Z]{3}$/ => {
        country: "Malaysia",
        dash: 2 },
      /^PH(([A-Z]{3})|(1[A-Z]{2})|(\d[A-Z]\d)|([1-9]\d{2,3}))$/ => {
        country: "Netherlands",
        dash: 2 },
      /^ZK[A-Z]{3}$/ => {
        country: "New Zealand",
        dash: 2 },
      /^LN[A-Z]{3}$/ => {
        country: "Norway",
        dash: 2 },
      /^9V[A-Z]{3}$/ => {
        country: "Singapore",
        dash: 2 },
      /^HL[0-9C]\d{3}$/ => {
        country: "South Korea",
        dash: 0 },
      /^SE[A-Z]([A-Z0-9][A-Z1-9]|[A-Z1-9][A-Z0-9])$/ => {
        country: "Sweden",
        dash: 2 },
      /^B\d{5}$/ => {
        country: "Taiwan",
        dash: 1 },
      /^HS[A-Z]{3}$/ => {
        country: "Thailand",
        dash: 2 },
      /^UR(([A-Z]{3,4})|([1-9]\d{4}))$/ => {
        country: "Ukraine",
        dash: 2 },
      /^A6[A-Z]{3}$/ => {
        country: "United Arab Emirates",
        dash: 2 }
      }
    return tail_formats
  end

  # Determines the country of a tail number and adds appropriate dashes to
  # match that country's tail number format.
  #
  # @param tail_number [String] a formatted or simplified tail number
  # @return [Hash{Symbol => String}] a country name and formatted tail number
  # @example
  #   TailNumber.country_format("VHOQI") #=> {country: "Australia", tail: "VH-OQI"}
  #   TailNumber.country_format("N909EV") #=> {country: "United States", tail: "N909EV"}
  def self.country_format(tail_number)
    tail_number = simplify(tail_number)
    country = countries.find{|k,v| k.match(tail_number) }&.last
    return {country: nil, tail: tail_number} if country.nil?
    return {country: country[:country], tail: tail_number} if country[:dash] == 0
    tail = "#{tail_number[0...country[:dash]]}-#{tail_number[country[:dash]..-1]}"
    return {country: country[:country], tail: tail}
  end
  
end