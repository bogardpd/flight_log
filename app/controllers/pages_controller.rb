# encoding: UTF-8

class PagesController < ApplicationController
  def home
  end

  def about
    @title = "About Paul"
  end

  def projects
    @title = "Projects"
    @gcmap_used = true
  end

  def resume
    @title = 'Résumé'
  end
  
  def other
    @title = "Other"
  end
  
  
  def computers
    @title = "Computers"
  end
  
  def computer_history
    @title = "Computer History"
  end
  
  def cooking
    @title = "Experiments in Cooking"
  end
  
  def current_home
    @title = "Paul's Current Home"
  end
  
  def ebdb
    @title = "EarthBound Database"
  end
  
  def flight_log
    # Description of how flight log was created
    @title = "Creating Paul Bogard's Flight Log"
  end
  
  def flightlog
    # Flight Log Index
    @meta_description = "Paul Bogard's Flight Log shows maps and tables for various breakdowns of Paul's flight history."
    @logo_used = true
    
    if logged_in?
      @flights = Flight.chronological
      @flight_aircraft = Flight.where("aircraft_family IS NOT NULL").group("aircraft_family").count
      @flight_airlines = Flight.where("airline_id IS NOT NULL").group("airline").count
      @flight_tail_numbers = Flight.where("tail_number IS NOT NULL").group("tail_number").count
    else # Filter out hidden trips for visitors
      @flights = Flight.visitor.chronological
      @flight_aircraft = Flight.visitor.where("aircraft_family IS NOT NULL").group("aircraft_family").count
      @flight_airlines = Flight.visitor.where("airline IS NOT NULL").group("airline").count
      @flight_tail_numbers = Flight.visitor.where("tail_number IS NOT NULL").group("tail_number").count
    end
    
    @total_distance = total_distance(@flights)
    @hidden_trips = Trip.where(:hidden => true)
    
    if @flights.any?
    
      @airport_array = Airport.frequency_array(@flights)

      @route_totals = Hash.new(0)
      route_distances = Hash.new()
    
      @flights.each do |flight|
        airport_alphabetize = [flight.origin_airport.iata_code,flight.destination_airport.iata_code].sort
        @route_totals["#{airport_alphabetize[0]}-#{airport_alphabetize[1]}"] += 1
        route_distances[[airport_alphabetize[0],airport_alphabetize[1]]] = route_distance_by_iata(airport_alphabetize[0],airport_alphabetize[1]) if route_distance_by_iata(airport_alphabetize[0],airport_alphabetize[1])
      end
      @route_totals = @route_totals.sort_by {|key, value| [-value, key]}
    
      @route_superlatives = superlatives_collection(route_distances)
  
      @aircraft_array = Array.new
      @flight_aircraft.each do |aircraft, count| 
        @aircraft_array.push({:aircraft => aircraft, :count => count})
      end
      @aircraft_array = @aircraft_array.sort_by { |aircraft| [-aircraft[:count], aircraft[:aircraft]] }
    
      @airlines_array = Array.new
      @flight_airlines.each do |airline, count| 
        @airlines_array.push({name: airline.airline_name, iata_code: airline.iata_airline_code, count: count})
      end
      @airlines_array = @airlines_array.sort_by { |airline| [-airline[:count], airline[:name]] }
    
      @tails_array = Array.new
      @flight_tail_numbers.each do |tail_number, count| 
        @tails_array.push({:tail_number => tail_number, :count => count})
      end
      @tails_array = @tails_array.sort_by { |tail| [-tail[:count], tail[:tail_number]] }
    end
    
  end
  
  def gps_log
    @title = "GPS Log"
  end
  
  def gps_logging_garmin
    @title = "Garmin GPS Logging"
  end
  
  def gps_logging_iphone
    @title = "iPhone GPS Logging"
  end
  
  def hotel_internet_quality
    @title = "Hotel Internet Quality"
  end
  
  def itinerary
    render :layout => false
  end
  
  def modeling
    @title = "CAD 3D Models"
  end
  
  def stephenvlog
    @title = "StephenVlog Appearances"
    @vlogs = Array.new
  end
  
  def tulsa_penguins
    @title = "Tulsa Penguins"
    @penguins = Array.new
  end
  
  def turn_signal_counter
    @title = "Turn Signal Counter"
  end
  
  def visor_cam
    @title = "Visor Cam"
  end
  
  def pax_prime_2012
    @title = "PAX Prime 2012"
  end
  
  private
  


end
