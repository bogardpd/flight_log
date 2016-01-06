# encoding: UTF-8

class PagesController < ApplicationController

  
  def flightlog
    # Flight Log Index
    @meta_description = "Paul Bogard's Flight Log shows maps and tables for various breakdowns of Paul's flight history."
    @logo_used = true
    @default_region = :conus
    
    if logged_in?
      @flights = Flight.flights_table
      @flight_aircraft = Flight.find_by_sql("SELECT aircraft_families.iata_aircraft_code, aircraft_families.family_name, aircraft_families.manufacturer, COUNT(*) as flight_count FROM flights JOIN aircraft_families ON aircraft_families.id = flights.aircraft_family_id WHERE flights.aircraft_family_id IS NOT NULL GROUP BY aircraft_families.iata_aircraft_code, aircraft_families.family_name, aircraft_families.manufacturer ORDER BY flight_count DESC")
      @flight_airlines = Flight.find_by_sql("SELECT airlines.iata_airline_code, airlines.airline_name, COUNT(*) as flight_count FROM flights JOIN airlines ON airlines.id = flights.airline_id WHERE flights.airline_id IS NOT NULL GROUP BY airlines.iata_airline_code, airlines.airline_name ORDER BY flight_count DESC")
      @flight_tail_numbers = Flight.where("tail_number IS NOT NULL").group("tail_number").count
    else # Filter out hidden trips for visitors
      @flights = Flight.visitor.flights_table
      @flight_aircraft = Flight.find_by_sql("SELECT aircraft_families.iata_aircraft_code, aircraft_families.family_name, aircraft_families.manufacturer, COUNT(*) as flight_count FROM flights JOIN aircraft_families ON aircraft_families.id = flights.aircraft_family_id JOIN trips ON trips.id = flights.trip_id WHERE flights.aircraft_family_id IS NOT NULL AND trips.hidden = false GROUP BY aircraft_families.iata_aircraft_code, aircraft_families.family_name, aircraft_families.manufacturer ORDER BY flight_count DESC")
      @flight_airlines = Flight.find_by_sql("SELECT airlines.iata_airline_code, airlines.airline_name, COUNT(*) as flight_count FROM flights JOIN airlines ON airlines.id = flights.airline_id JOIN trips ON trips.id = flights.trip_id WHERE flights.airline_id IS NOT NULL AND trips.hidden = false GROUP BY airlines.iata_airline_code, airlines.airline_name ORDER BY flight_count DESC")
      @flight_tail_numbers = Flight.visitor.where("tail_number IS NOT NULL").group("tail_number").count
    end
    
    @total_distance = total_distance(@flights)
    @hidden_trips = Trip.where(:hidden => true)
    
    if @flights.any?
    
      @airport_array = Airport.frequency_array(@flights)

      # Create superlatives:
      @route_totals = Hash.new(0)
      route_distances = Hash.new()
      route_hash = Hash.new()
      Route.find_by_sql("SELECT routes.distance_mi, airports1.iata_code AS iata1, airports2.iata_code AS iata2 FROM routes JOIN airports AS airports1 ON airports1.id = routes.airport1_id JOIN airports AS airports2 ON airports2.id = routes.airport2_id").map{|x| route_hash[[x.iata1,x.iata2]] = x.distance_mi }
      @flights.each do |flight|
        airport_alphabetize = [flight.origin_iata_code,flight.destination_iata_code].sort
        @route_totals[[airport_alphabetize[0],airport_alphabetize[1]]] += 1
        route_distances[[airport_alphabetize[0],airport_alphabetize[1]]] = route_hash[[airport_alphabetize[0],airport_alphabetize[1]]] || route_hash[[airport_alphabetize[1],airport_alphabetize[0]]] || 0
      end
      @route_totals = @route_totals.sort_by {|key, value| [-value, key]}
      @route_superlatives = superlatives_collection(route_distances)
=begin            
      @aircraft_array = Array.new
      @flight_aircraft.each do |aircraft, count| 
        @aircraft_array.push({:aircraft => aircraft, :count => count})
      end
      @aircraft_array = @aircraft_array.sort_by { |aircraft| [-aircraft[:count], aircraft[:aircraft]] }
=end
      @tails_array = Array.new
      @flight_tail_numbers.each do |tail_number, count| 
        @tails_array.push({:tail_number => tail_number, :count => count})
      end
      @tails_array = @tails_array.sort_by { |tail| [-tail[:count], tail[:tail_number]] }
    
    end

  end
  


end
