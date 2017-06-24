module TailNumber
  
  def self.country(tail_number)
    case tail_number.upcase
    when /^N[1-9]((\d{0,4})|(\d{0,3}[A-HJ-NP-Z])|(\d{0,2}[A-HJ-NP-Z]{2}))$/
      return "United States"
    when /^VH-[A-Z]{3}$/
      return "Australia"
    when /^C-[FGI][A-Z]{3}$/
      return "Canada"
    when /^B-((1[5-9]\d{2})|([2-9]\d{3}))$/
      return "China"
    when /^F-[A-Z]{4}$/
      return "France"
    when /^D-(([A-CE-IK-O][A-Z]{3})|(\d{4}))$/
      return "Germany"
    when /^9G-[A-Z]{3}$/
      return "Ghana"
    when /^SX-[A-Z]{3}$/
      return "Greece"
    when /^B-[HKL][A-Z]{2}$/
      return "Hong Kong"
    when /^TF-(([A-Z]{3})|([1-9]\d{2}))$/
      return "Iceland"
    when /^VT-[A-Z]{3}$/
      return "India"
    when /^4X-[A-Z]{3}$/
      return "Israel"
    when /^JA((\d{4})|(\d{3}[A-Z])|(\d{2}[A-Z]{2})|(A\d{3}))$/
      return "Japan"
    when /^JY-[A-Z]{3}$/
      return "Jordan"
    when /^9M-[A-Z]{3}$/
      return "Malaysia"
    when /^PH-(([A-Z]{3})|(1[A-Z]{2})|(\d[A-Z]\d)|([1-9]\d{2,3}))$/
      return "Netherlands"
    when /^ZK-[A-Z]{3}$/
      return "New Zealand"
    when /^9V-[A-Z]{3}$/
      return "Singapore"
    when /^B-((\d(0\d{3}|1[0-4]\d{2}))|([1-9]\d{4}))$/
      return "Taiwan"
    when /^HS-[A-Z]{3}$/
      return "Thailand"
    when /^UR-(([A-Z]{3,4})|([1-9]\d{4}))$/
      return "Ukraine"
    when /^A6-[A-Z]{3}$/
      return "United Arab Emirates"
    when /^G-(([A-Z]{4})|(\d{1,2}-\d{1,2}))$/
      return "United Kingdom"
    else
      return nil
    end
      
  end
  
  # Returns a hash of tail numbers, aircraft codes (ICAO preferred), aircraft
  # manufacturers, aircraft family/type names, airline names, airline IATA
  # codes, and flight counts
  def self.flight_count(logged_in=false)
    flights = logged_in ? Flight.all : Flight.visitor
    tail_counts = flights.joins(:aircraft_family).joins(:airline).where.not(tail_number: nil).group(:tail_number).count
    tail_details = flights.joins(:aircraft_family).joins(:airline).select(:tail_number, :iata_airline_code, :airline_name, :icao_aircraft_code, :iata_aircraft_code, :manufacturer, :family_name, :departure_utc).where.not(tail_number:nil)
    return nil unless tail_details.any?
    tail_details.map{|t| {t.tail_number => {
      airline_code:  t.iata_airline_code,
      airline_name:  t.airline_name,
      aircraft_code: t.icao_aircraft_code || t.iata_aircraft_code,
      manufacturer:  t.manufacturer,
      family_name:   t.family_name,
      departure_utc: t.departure_utc
    }}}
      .reduce{|a,b| a.merge(b){|k,oldval,newval| newval[:departure_utc] > oldval[:departure_utc] ? newval : oldval}}
      .merge(tail_counts){|k,oldval,newval| oldval.store(:count, newval); oldval}
      .map{|k,v| {
        tail_number:  k,
        count:        v[:count],
        aircraft:     v[:aircraft_code] || "",
        airline_name: v[:airline_name] || "",
        airline_code: v[:airline_code] || "",
        manufacturer: v[:manufacturer],
        family_name:  v[:family_name]
      }}
      .sort_by{|t| [-(t[:count] || 0), t[:tail_number] || ""]}
  end
  
end