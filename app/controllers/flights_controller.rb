class FlightsController < ApplicationController
  protect_from_forgery except: :show_boarding_pass_json
  before_action :logged_in_user, :only => [:new, :create, :edit, :update, :destroy, :index_emails]
  add_breadcrumb 'Home', 'root_path'
  
  def index
    add_breadcrumb 'Flights', 'flights_path'
    @logo_used = true
    @title = "Flights"
    @region = current_region(default: :world)
        
    if logged_in?
      @flights = Flight.flights_table
    else
      @flights = Flight.flights_table.visitor
    end
    
    @year_range = @flights.year_range
    
    if @flights.any?
    
      @map = FlightsMap.new(@flights, region: @region)
      
      @total_distance = total_distance(@flights)
    
      # Determine which years have flights:
      @years_with_flights = Hash.new(false)
      @flights.each do |flight|
        @years_with_flights[flight.departure_date.year] = true
      end
      @meta_description = "Maps and lists of all of Paul Bogardʼs flights."
    
      # Sort flight table:
      sort_params = sort_parse(params[:sort], %w(departure), :asc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
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
    
    # Create map:
    @map = SingleFlightMap.new(@flight)
    
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
    @meta_description = "Details for Paul Bogardʼs #{@flight.airline.airline_name} #{@flight.flight_number} flight on #{format_date(@flight.departure_date)}."
    
    @route_distance = route_distance_by_airport_id(@flight.origin_airport, @flight.destination_airport)
    
    @boarding_pass = BoardingPass.new(@flight.boarding_pass_data, flight: @flight)
    
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb @title, "flight_path(#{params[:id]})"
    
    add_admin_action view_context.link_to("Delete Flight", :flight, :method => :delete, :data => {:confirm => "Are you sure you want to delete this flight?"}, :class => 'warning')
    add_admin_action view_context.link_to("Edit Flight", edit_flight_path(@flight))
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldnʼt find a flight with an ID of #{params[:id]}. Instead, weʼll give you a list of flights."
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
      @meta_description = "Maps and lists of Paul Bogardʼs flights in #{params[:year]}"
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
      @meta_description = "Maps and lists of Paul Bogardʼs flights from #{format_date(params[:start_date].to_date)} to #{format_date(params[:end_date].to_date)}"
    else
      raise ArgumentError.new('No date parameters were given for a date range')
    end
    
    @in_text = params[:year].present? ? params[:year] : "this date range"
    @new_airport_flag = false
    @new_aircraft_flag = false
    @new_airline_tag = false
    
    if logged_in?
      @flights = Flight.flights_table.where(:departure_date => @date_range)
      @year_range = Flight.year_range
      @years_with_flights = Flight.years_with_flights
    else
      @flights = Flight.visitor.flights_table.where(:departure_date => @date_range)
      @year_range = Flight.visitor.year_range
      @years_with_flights = Flight.visitor.years_with_flights
    end
    
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @region = current_region(default: :world)
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = total_distance(@flights)
    
    @airport_array = Airport.airport_table(@flights)
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
    flash[:record_not_found] = "We couldnʼt find any flights in #{@in_text}. Instead, weʼll give you a list of flights."
    redirect_to flights_path
    
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
      
      total_flights_with_class = 0
      @flight_classes.each do |travel_class, count| 
        @classes_array.push({:travel_class => travel_class, :count => count})
        total_flights_with_class += count
      end
      
      # Find maxima for graph scaling:
      @classes_maximum = @classes_array.max_by{|i| i[:count]}[:count]
      
      # Sort aircraft table:
      sort_params = sort_parse(params[:sort], %w(class flights), :asc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
      sort_mult   = (@sort_dir == :asc ? 1 : -1)
      case @sort_cat
      when :class
        @classes_array = @classes_array.sort_by { |travel_class| travel_class[:travel_class] }
        @classes_array.reverse! if @sort_dir == :desc
      when :flights
        @classes_array = @classes_array.sort_by { |travel_class| [sort_mult*travel_class[:count], travel_class[:travel_class]] }
      end
      
      @unknown_class_flights = Flight.all.length - total_flights_with_class
    end
  end
  
  def show_class
    @logo_used = true
    
    @flights = Flight.flights_table.where(:travel_class => params[:travel_class])
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    
    @title = Flight.classes_list[params[:travel_class]].titlecase + " Class"
    @meta_description = "Maps and lists of Paul Bogardʼs #{Flight.classes_list[params[:travel_class]].downcase} class flights."
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    add_breadcrumb 'Travel Classes', 'classes_path'
    add_breadcrumb Flight.classes_list[params[:travel_class]].titlecase, show_class_path(params[:travel_class])

    @region = current_region(default: :world)
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = total_distance(@flights)

    # Create comparitive lists of airlines, operators, and aircraft:
    airline_frequency(@flights)
    operator_frequency(@flights)
    aircraft_frequency(@flights)

    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:record_not_found] = "We couldnʼt find any flights in #{@title}. Instead, weʼll give you a list of travel classes."
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
    @meta_description = "A list of the individual airplanes Paul Bogard has flown on, and how often heʼs flown on each."
    
    @tail_numbers_table = Array.new
    
    if @flight_tail_numbers.any?
    
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
      sort_params = sort_parse(params[:sort], %w(flights tail aircraft airline), :desc)
      @sort_cat   = sort_params[:category]
      @sort_dir   = sort_params[:direction]
      sort_mult   = (@sort_dir == :asc ? 1 : -1)
      case @sort_cat
      when :tail
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| tail[:tail_number]}
        @tail_numbers_table.reverse! if @sort_dir == :desc
      when :flights
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [sort_mult*tail[:count], tail[:tail_number]]}
      when :aircraft
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [tail[:aircraft], tail[:airline_name]]}
        @tail_numbers_table.reverse! if @sort_dir == :desc
      when :airline
        @tail_numbers_table = @tail_numbers_table.sort_by {|tail| [tail[:airline_name], tail[:aircraft]]}
        @tail_numbers_table.reverse! if @sort_dir == :desc
      end
    end
  end
  
  def show_tail
    @logo_used = true
    @flights = Flight.where(:tail_number => params[:tail_number])
    @flights = @flights.flights_table
    @flights = @flights.visitor if !logged_in? # Filter out hidden trips for visitors
    
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    @title = params[:tail_number]
    @meta_description = "Maps and lists of Paul Bogardʼs flights on tail number #{params[:tail_number]}."
    add_breadcrumb 'Tail Numbers', 'tails_path'
    add_breadcrumb @title, show_tail_path(params[:tail_number])
    
    @region = current_region(default: :world)
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = total_distance(@flights)
    
    # Create comparitive list of airlines, operators, and classes:
    airline_frequency(@flights)
    operator_frequency(@flights)
    class_frequency(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
   flash[:record_not_found] = "We couldnʼt find any flights with the tail number #{params[:tail_number]}. Instead, weʼll give you a list of tail numbers."
    redirect_to tails_path
  end
  
  def index_emails
    @title = "Import Boarding Passes"
    add_breadcrumb 'Flights', 'flights_path'
    add_breadcrumb @title, index_emails_path
    
    # Get attachments from boarding pass emails
    begin
      attachments = BoardingPassEmail::process_attachments(current_user.all_emails)
    rescue SocketError => details
      @passes = nil
      @error = "Could not connect to email (#{details})"
    end
    
    @passes = PKPass.all
    
  end
  
  def input_boarding_pass
    @title = "Boarding Pass Parser"
    @meta_description = "A boarding pass barcode parser."
    add_breadcrumb @title, boarding_pass_path
  end
  
  def build_boarding_pass
    if params[:data].present?
      redirect_to show_boarding_pass_path(params[:data])
    else
      flash[:alert] = "Boarding pass data cannot be blank."
      redirect_to boarding_pass_path
    end
  end
  
  def show_boarding_pass
    @title = "Boarding Pass Results"
    @meta_description = "Results from the boarding pass barcode parser."
    add_breadcrumb "Boarding Pass", boarding_pass_path
    
    @boarding_pass = BoardingPass.new(params[:data])
    #if @boarding_pass.leg_operating_carrier_designator(0)
    if @boarding_pass.data.dig(:repeated, 0, :mandatory, 42)
      bp_string = "#{@boarding_pass.data.dig(:repeated, 0, :mandatory, 42, :raw)} #{@boarding_pass.data.dig(:repeated, 0, :mandatory, 43, :raw)} #{@boarding_pass.data.dig(:repeated, 0, :mandatory, 26, :raw)} ✈ #{@boarding_pass.data.dig(:repeated, 0, :mandatory, 38, :raw)}"
      @title += ": #{bp_string}"
      add_breadcrumb bp_string, boarding_pass_path
    else
      add_breadcrumb "Results", boarding_pass_path
    end
    
  end
  
  def show_boarding_pass_json
    boarding_pass = BoardingPass.new(params[:data])
    if params[:callback]
      render :json => boarding_pass.data, :callback => params[:callback]
    else
      render :json => boarding_pass.data
    end
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
      flash[:success] = "Successfully added #{@flight.airline.airline_name} #{@flight.flight_number}."
      if (@flight.tail_number.present? && Flight.where(:tail_number => @flight.tail_number).count > 1)
        flash[:success] += " Youʼve had prior flights on this tail!"
      end
      if (@flight.departure_date.to_time - @flight.departure_utc.to_time).to_i.abs > 60*60*24*2
        flash[:alert] = "Your departure date and UTC time are more than a day apart &ndash; are you sure theyʼre correct?".html_safe
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
      if (@flight.departure_date.to_time - @flight.departure_utc.to_time).to_i.abs > 60*60*24*2
        flash[:alert] = "Your departure date and UTC time are more than a day apart &ndash; are you sure they're correct?".html_safe
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
    
    
  
    
    
end
