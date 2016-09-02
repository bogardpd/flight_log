# encoding: UTF-8

class PagesController < ApplicationController

  def flightlog
    # Flight Log Index
    @meta_description = "Paul Bogardʼs Flight Historian shows maps and tables for various breakdowns of Paulʼs flight history."
    @logo_used = true
    @region = current_region(default: :conus)
    
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
    
      @map = FlightsMap.new(@flights, region: @region)
    
      @airport_array = Airport.airport_table(@flights)

      # Create route totals hash:
      @route_totals = Hash.new(0)
      @flights.each do |flight|
        airport_alphabetize = [flight.origin_iata_code,flight.destination_iata_code].sort
        @route_totals[[airport_alphabetize[0],airport_alphabetize[1]]] += 1
      end      
      @route_totals = @route_totals.sort_by {|key, value| [-value, key]}
      
      # Create superlatives:
      @route_superlatives = superlatives(@flights)

      @tails_array = Array.new
      @flight_tail_numbers.each do |tail_number, count| 
        @tails_array.push({:tail_number => tail_number, :count => count})
      end
      @tails_array = @tails_array.sort_by { |tail| [-tail[:count], tail[:tail_number]] }
    
    end

  end
  
  def letsencrypt
    render text: ""
  end
  
  def gcmap_image_proxy
    require 'open-uri'
    
    query = params[:query].gsub('_','/')
    
    response.headers['Cache-Control'] = "public, max-age=#{84.hours.to_i}"
    response.headers['Content-Type'] = 'image/gif'
    response.headers['Content-Disposition'] = 'inline'
    
    if Map.hash_image_query(query) == params[:check] # Ensure the query was issued by this application
      image_url = "http://www.gcmap.com/map?PM=#{params[:airport_options]}&MP=r&MS=wls2&P=#{query}"
      render :text => open(image_url, "rb").read
    else
      render :text => ""
    end
  end

end