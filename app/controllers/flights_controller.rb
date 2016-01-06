class FlightsController < ApplicationController
  before_filter :logged_in_user, :only => [:new, :create, :edit, :update, :destroy]
  add_breadcrumb 'Home', 'root_path'
  
  def index
    add_breadcrumb 'Flights', 'flights_path'
    @logo_used = true
    @title = "Flights"
        
    if logged_in?
      #@flights = Flight.chronological
      @flights = Flight.flights_table
      @year_range = @flights.any? ? Flight.chronological.first.departure_date.year..Flight.chronological.last.departure_date.year : nil
    else
      @flights = Flight.flights_table.visitor
      @year_range = @flights.any? ? Flight.visitor.chronological.first.departure_date.year..Flight.visitor.chronological.last.departure_date.year : nil
    end
    
    if @flights.any?
    
      @total_distance = total_distance(@flights)
    
      # Determine which years have flights:
      @years_with_flights = Hash.new(false)
      @flights.each do |flight|
        @years_with_flights[flight.departure_date.year] = true
      end
      @meta_description = "Maps and lists of all of Paul Bogard's flights."
    
      # Set values for sort:
      case params[:sort_category]
      when "departure"
        @sort_cat = :departure
      else
        @sort_cat = :departure
      end
    
      case params[:sort_direction]
      when "asc"
        @sort_dir = :asc
      when "desc"
        @sort_dir = :desc
      else
        @sort_dir = :asc
      end
          
      # Sort flight table:
      @flights = @flights.reverse_order if @sort_dir == :desc
    
    end
  
  end
  
  def show
    @logo_used = true
    if logged_in?
      @flight = Flight.find(params[:id])
      @city_pair_flights = Flight.where("(origin_airport_id = :city1 AND destination_airport_id = :city2) OR (origin_airport_id = :city2 AND destination_airport_id = :city1)", {:city1 => @flight.origin_airport.id, :city2 => @flight.destination_airport.id})
    else
      @flight = Flight.visitor.find(params[:id])
      @city_pair_flights = Flight.visitor.where("(origin_airport_id = :city1 AND destination_airport_id = :city2) OR (origin_airport_id = :city2 AND destination_airport_id = :city1)", {:city1 => @flight.origin_airport.id, :city2 => @flight.destination_airport.id})
    end
    
    # Get trips sharing this city pair:
    trip_array = Array.new
    @city_pair_flights = Array.new
    section_where_array = Array.new
    @city_pair_flights.each do |flight|
      trip_array.push(flight.trip_id)
      @sections.push( {:trip_id => flight.trip_id, :trip_name => flight.trip.name, :trip_section => flight.trip_section, :departure => flight.departure_date} )
      section_where_array.push("(trip_id = #{flight.trip_id.to_i} AND trip_section = #{flight.trip_section.to_i})")
    end
    trip_array = trip_array.uniq
    
    # Create list of trips sorted by first flight:
    if logged_in?
      @trips = Trip.find(trip_array).sort_by{ |trip| trip.flights.first.departure_date }
    else
      @trips = Trip.visitor.find(trip_array).sort_by{ |trip| trip.flights.first.departure_date }
    end
    
    # Create flight arrays for maps of trips and sections:
    @city_pair_trip_flights = Flight.where(:trip_id => trip_array)
    @city_pair_section_flights = Flight.where(section_where_array.join(' OR '))
    
    @title = @flight.airline.airline_name + " " + @flight.flight_number.to_s
    @meta_description = "Details for Paul Bogard's #{@flight.airline} #{@flight.flight_number} flight on #{format_date(@flight.departure_date)}."
    
    @route_distance = route_distance_by_airport_id(@flight.origin_airport, @flight.destination_airport)
    
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb @title, "flight_path(#{params[:id]})"
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find a flight with an ID of #{params[:id]}. Instead, we'll give you a list of flights."
    redirect_to flights_path
  end
    
  def show_date_range
    add_breadcrumb 'Flights', 'flights_path'
    @logo_used = true
    
    if params[:year].present?
      @date_range = ("#{params[:year]}-01-01".to_date)..("#{params[:year]}-12-31".to_date)
      add_breadcrumb params[:year], "flights_path(:year => #{params[:year]})"
      @date_range_text = "in #{params[:year]}"
      @flight_list_title = params[:year] + " Flight List"
      @superlatives_title = params[:year] + " Longest and Shortest Routes"
      @superlatives_title_nav = @superlatives_title.downcase
      @title = "Flights in #{params[:year]}"
    elsif (params[:start_date].present? && params[:end_date].present?)
      if (params[:start_date] > params[:end_date])
        raise ArgumentError.new('Start date cannot be later than end date')
      end

      @date_range = (params[:start_date].to_date)..(params[:end_date].to_date)
      add_breadcrumb "#{format_date(params[:start_date].to_date)} - #{format_date(params[:end_date].to_date)}", "flights_path(:start_date => '#{params[:start_date]}', :end_date => '#{params[:end_date]}')"
      @date_range_text = "from #{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @flight_list_title = "Flight List for #{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @superlatives_title = "Longest and Shortest Routes for#{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @superlatives_title_nav = "Longest and shortest routes for#{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
      @title = "Flights: #{format_date(params[:start_date].to_date)} - #{format_date(params[:end_date].to_date)}"
    else
      raise ArgumentError.new('No date parameters were given for a date range')
    end
    
    @in_text = params[:year].present? ? params[:year] : "this date range"
    @new_airport_flag = false
    @new_aircraft_flag = false
    @new_airline_tag = false
    
    @years_with_flights = years_with_flights
    @year_range = years_with_flights_range
        
    if logged_in?
      @flights = Flight.flights_table.where(:departure_date => @date_range)
    else
      @flights = Flight.visitor.flights_table.where(:departure_date => @date_range)
    end
    
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @total_distance = total_distance(@flights)
    
    @airport_array = Airport.frequency_array(@flights)
    @airport_maximum = @airport_array.first[:frequency]
      
    # Create comparitive lists of airlines and classes:
    airline_frequency(@flights)
    aircraft_frequency(@flights)
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ArgumentError
    redirect_to flights_path
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights in #{@in_text}. Instead, we'll give you a list of flights."
    redirect_to flights_path
    
  end
    
  
    
  def show_aircraft
    @logo_used = true
    @aircraft_family = params[:aircraft_family].gsub("_", " ")
    @title = @aircraft_family
    @meta_description = "Maps and lists of Paul Bogard's flights on #{@aircraft_family} aircraft."
    @flights = Flight.flights_table.where(:aircraft_family => @aircraft_family)
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    add_breadcrumb 'Aircraft Families', 'aircraft_families_path'
    add_breadcrumb @aircraft_family, aircraft_families_path(@aircraft_family.gsub(" ", "_"))
    
    @total_distance = total_distance(@flights)
    
    # Create comparitive lists of airlines and classes:
    airline_frequency(@flights)
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights on #{@aircraft_family} aircraft. Instead, we'll give you a list of aircraft."
    redirect_to aircraft_families_path
  end
  
    
  def index_classes
    add_breadcrumb 'Travel Classes', 'classes_path'
    if logged_in?
      @flight_classes = Flight.where("travel_class IS NOT NULL").group("travel_class").count
    else # Filter out hidden trips for visitors
      @flight_classes = Flight.visitor.where("travel_class IS NOT NULL").group("travel_class").count
    end
    @title = "Travel Classes"
    @meta_description = "A count of how many times Paul Bogard has flown in each class."
    @classes_array = Array.new
    
    if @flight_classes.any?
      @flight_classes.each do |travel_class, count| 
        @classes_array.push({:travel_class => travel_class, :count => count})
      end
      @classes_array = @classes_array.sort_by { |travel_class| [-travel_class[:count], travel_class[:travel_class]] }
      @classes_maximum = @classes_array.first[:count]
    end
  end
  
  def show_class
    @logo_used = true
    
    @flights = Flight.flights_table.where(:travel_class => params[:travel_class])
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    
    @title = params[:travel_class].titlecase + " Class"
    @meta_description = "Maps and lists of Paul Bogard's #{params[:travel_class].downcase} class flights."
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    add_breadcrumb 'Travel Classes', 'classes_path'
    add_breadcrumb params[:travel_class].titlecase, show_class_path(params[:travel_class])

    @total_distance = total_distance(@flights)

    # Create comparitive lists of airlines and aircraft:
    airline_frequency(@flights)
    aircraft_frequency(@flights)

    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights in #{@title}. Instead, we'll give you a list of travel classes."
    redirect_to classes_path
  end

  def index_tails
    add_breadcrumb 'Tail Numbers', 'tails_path'
    if logged_in?
      @flight_tail_numbers = Flight.where("tail_number IS NOT NULL").group("tail_number").count
      @flight_tail_details = Flight.select(:tail_number, :iata_aircraft_code, :airline_name, :iata_airline_code, :family_name, :manufacturer).joins(:airline, :aircraft_family).chronological.where("tail_number IS NOT NULL")
    else # Filter out hidden trips for visitors
      @flight_tail_numbers = Flight.visitor.where("tail_number IS NOT NULL").group("tail_number").count
      @flight_tail_details = Flight.visitor.select(:tail_number, :iata_aircraft_code, :airline_name, :iata_airline_code, :family_name, :manufacturer).joins(:airline, :aircraft_family).chronological.where("tail_number IS NOT NULL")
    end
    @title = "Tail Numbers"
    @meta_description = "A list of the individual airplanes Paul Bogard has flown on, and how often he's flown on each."
    
    @tail_numbers_table = Array.new
    
    if @flight_tail_numbers.any?
    
      # Set values for sort:
      case params[:sort_category]
      when "tail"
        @sort_cat = :tail
      when "flights"
        @sort_cat = :flights
      when "aircraft"
        @sort_cat = :aircraft
      when "airline"
        @sort_cat = :airline
      else
        @sort_cat = :flights
      end
    
      case params[:sort_direction]
      when "asc"
        @sort_dir = :asc
      when "desc"
        @sort_dir = :desc
      else
        @sort_dir = :desc
      end
    
      sort_mult = (@sort_dir == :asc ? 1 : -1)
    
      # Create tail number count array    
      tails_count = Array.new
      @flight_tail_numbers.each do |tail_number, count| 
        tails_count.push({:tail_number => tail_number, :count => count})
      end
    
      # Create details array, using the latest flight for each tail number.
      tails_airline_name_hash = Hash.new
      tails_airline_iata_hash = Hash.new
      tails_aircraft_hash = Hash.new
      tails_manufacturer_hash = Hash.new
      tails_aircraft_name_hash = Hash.new
      @flight_tail_details.each do |tail|
        tails_airline_name_hash[tail.tail_number] = tail.airline_name
        tails_airline_iata_hash[tail.tail_number] = tail.iata_airline_code
        tails_aircraft_hash[tail.tail_number] = tail.iata_aircraft_code
        tails_manufacturer_hash[tail.tail_number] = tail.manufacturer
        tails_aircraft_name_hash[tail.tail_number] = tail.family_name
      end
    
      # Create table array
      tails_count.each do |tail|
        @tail_numbers_table.push({:tail_number => tail[:tail_number], :count => tail[:count], :aircraft => tails_aircraft_hash[tail[:tail_number]] || "", :airline_name => tails_airline_name_hash[tail[:tail_number]] || "", airline_iata: tails_airline_iata_hash[tail[:tail_number]] || "", manufacturer: tails_manufacturer_hash[tail[:tail_number]] || "", family_name: tails_aircraft_name_hash[tail[:tail_number]] || ""})
      end
    
      # Find maxima for graph scaling:
      @flights_maximum = @tail_numbers_table.max_by{|i| i[:count]}[:count]
    
      # Sort tails table:
      case @sort_cat
      when :tail
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| tail[:tail_number]}
        @tail_numbers_table.reverse! if @sort_dir == :desc
      when :flights
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [sort_mult*tail[:count], tail[:tail_number]]}
      when :aircraft
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [tail[:aircraft], tail[:airline]]}
        @tail_numbers_table.reverse! if @sort_dir == :desc
      when :airline
        @tail_numbers_table = @tail_numbers_table.sort_by { |tail| [tail[:airline], tail[:aircraft]]}
        @tail_numbers_table.reverse! if @sort_dir == :desc
      end
    end
  end
  
  def show_tail
    @logo_used = true
    @flights = Flight.where(:tail_number => params[:tail_number])
    @flight_operators = @flights.where("operator_id IS NOT NULL").group("operator").count
    @flights = @flights.flights_table
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    
    
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    @title = params[:tail_number]
    @meta_description = "Maps and lists of Paul Bogard's flights on tail number #{params[:tail_number]}."
    add_breadcrumb 'Tail Numbers', 'tails_path'
    add_breadcrumb @title, show_tail_path(params[:tail_number])
    
    @total_distance = total_distance(@flights)
    
    # Create comparitive list of classes:
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
    # Create list of fleet numbers used by this tail:
    @operators_array = Array.new
    @flight_operators.each do |operator, count|
      @operators_array.push({name: operator.airline_name, iata_code: operator.iata_airline_code, count: count})
    end
    @operators_array = @operators_array.sort_by { |operator| [-operator[:count], operator[:operator]] }
    @operators_maximum = @flight_operators.length > 0 ? @operators_array.first[:count] : 1
    
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldn't find any flights with the tail number #{params[:tail_number]}. Instead, we'll give you a list of tail numbers."
    redirect_to tails_path
  end
  

    
  def new
    @title = "New Flight"
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb 'New Flight', 'new_flight_path'
    @flight = Trip.find(params[:trip_id]).flights.new
  end
    
  def create
    @flight = Trip.find(params[:flight][:trip_id]).flights.new(flight_params)
    if @flight.save
      flash[:success] = "Successfully added #{params[:flight][:airline]} #{params[:flight][:flight_number]}."
      if (@flight.tail_number.present? && Flight.where(:tail_number => @flight.tail_number).count > 1)
        flash[:success] += " You've had prior flights on this tail!"
      end
      redirect_to @flight
    else
      render 'new'
    end
  end
    
  def edit
    @flight = Flight.find(params[:id])
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb "#{@flight.airline.airline_name} #{@flight.flight_number}", 'flight_path(@flight)'
    add_breadcrumb 'Edit Flight', 'edit_flight_path(@flight)'
    @title = "Edit Flight"
  end
    
  def update
    @flight = Flight.find(params[:id])
    if @flight.update_attributes(flight_params)
      flash[:success] = "Successfully updated flight."
      if (@flight.tail_number.present? && Flight.where(:tail_number => @flight.tail_number).count > 1)
        flash[:success] += " You've had prior flights on this tail!"
      end
      redirect_to @flight
    else
      render 'edit'
    end
  end
    
  def destroy
    Flight.find(params[:id]).destroy
    flash[:success] = "Flight destroyed."
    redirect_to flights_path
  end
    
  private
  
    def flight_params
      params.require(:flight).permit(:aircraft_family_id, :aircraft_name, :aircraft_variant, :airline_id, :boarding_pass_data, :codeshare_airline_id, :codeshare_flight_number, :comment, :departure_date, :departure_utc, :destination_airport_id, :fleet_number, :flight_number, :operator_id, :origin_airport_id, :tail_number, :travel_class, :trip_id, :trip_section)
    end
    
    def logged_in_user
      redirect_to root_path unless logged_in?
    end
    
    
    
    def years_with_flights
      if logged_in?
        flights = Flight.chronological
      else
        flights = Flight.visitor.chronological
      end
    
      # Determine which years have flights:
      years_with_flights = Hash.new(false)
      flights.each do |flight|
        years_with_flights[flight.departure_date.year] = true
      end
      return years_with_flights
    end
    
    def years_with_flights_range
      if logged_in?
        return Flight.chronological.first.departure_date.year..Flight.last.departure_date.year
      else
        return Flight.visitor.chronological.first.departure_date.year..Flight.visitor.last.departure_date.year
      end
      return false      
    end
end
