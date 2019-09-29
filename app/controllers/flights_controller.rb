# Controls {Flight} pages and actions. Also controls pages for {TravelClass
# classes}, {TailNumber tail numbers}, and {BoardingPass} parsing.

class FlightsController < ApplicationController

  protect_from_forgery except: :show_boarding_pass_json
  before_action :logged_in_user, :only => [:new, :new_flight_menu, :change_trip, :create, :create_iata, :edit, :update, :destroy, :index_emails, :create_iata]
  
  # Shows a table of all {Flight Flights} flown.
  #
  # @return [nil]
  def index
    @logo_used = true
    @region = current_region(default: [])
    
    @flights = flyer.flights(current_user).includes(:airline, :origin_airport, :destination_airport, :trip)
        
    @year_range = @flights.year_range
    
    if @flights.any?
    
      @map = FlightsMap.new(@flights, region: @region)
      
      @total_distance = @flights.total_distance
    
      # Determine which years have flights:
      @years_with_flights = Hash.new(false)
      @flights.each do |flight|
        @years_with_flights[flight.departure_date.year] = true
      end
    
      # Sort flight table:
      @sort = Table.sort_parse(params[:sort], :departure, :asc)
      @flights = @flights.reverse_order if @sort[1] == :desc
    
    end
  
  end
  
  # Shows details for a particular {Flight}.
  #
  # {Flight} details:
  # * a {SingleFlightMap}
  # * the flight distance
  # * the administrating {Airline}, codeshare {Airline}, and {AirlinesController#show_operator operator}
  # * the flight number
  # * the {Trip} name and {TripsController#show_section section}
  # * the departure date
  # * the origin and destination {Airport Airports}
  # * the {AircraftFamily} and type
  # * the {TailNumber tail number}
  # * the {AirlinesController#show_fleet_number fleet number} and aircraft name
  # * the {TravelClass travel class}
  # * any comments
  # * a table of {BoardingPass} data and interpretations, if the user is a verified user
  #
  # @return [nil]
  def show
    @logo_used = true
    @flight = flyer.flights(current_user).find(params[:id])
    
    if @flight.trip.hidden? && logged_in?
      add_message(:warning, "This flight is part of a #{view_context.link_to("hidden trip", trip_path(@flight.trip))}!")
      check_email_for_boarding_passes
    end
    
    updated_pass = PKPass.where(flight_id: @flight)
    if updated_pass.any?
      add_message(:info, "This flight has an #{view_context.link_to("updated boarding pass", edit_flight_with_pass_path(pass_id: updated_pass.first))} available!")
    end
    
    @map = SingleFlightMap.new(@flight)
    @route_distance = Route.distance_by_airport(@flight.origin_airport, @flight.destination_airport)
    @boarding_pass = BoardingPass.new(@flight.boarding_pass_data, flight: @flight)
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find a flight with an ID of #{params[:id]}. Instead, weʼll give you a list of flights."
    redirect_to flights_path
  end

  # Shows a {https://www.topografix.com/gpx.asp GPX}-formatted XML document
  # representing a map of all flights the user has permission to view.
  #
  # @return [nil]
  # @see https://www.topografix.com/gpx.asp GPX: the GPS Exchange Format
  def show_flight_gpx
    flights = flyer.flights(current_user)
    render xml: FlightsMap.new(flights).gpx
  end

  # Shows a {https://developers.google.com/kml/ KML}-formatted XML document
  # representing a map of all flights the user has permission to view.
  #
  # @return [nil]
  # @see https://www.topografix.com/gpx.asp Keyhole Markup Language
  def show_flight_kml
    flights = flyer.flights(current_user)
    render xml: FlightsMap.new(flights).kml
  end
  
  # Shows data for all {Flight Flights} flown in a particular year or date
  # range.
  #
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}
  # * the total distance flown
  # * a table of {Airport Airports}, highlighting airports first flown during this date range
  # * a table of {Airline Airlines}, highlighting airlines first flown during this date range
  # * a table of {AircraftFamily AircraftFamilies}, highlighting families first flown during this date range
  # * a table of {TravelClass travel classes}, highlighting classes first flown during this date range
  # * the longest and shortest {Flight}
  #
  # @return [nil]
  def show_date_range
    @logo_used = true
    
    if params[:year].present?
      @year = params[:year].to_i
      @date_range = ("#{@year}-01-01".to_date)..("#{@year}-12-31".to_date)
      @date_range_text = "in #{@year}"
      @took_taken = @year == Date.today.year ? "have taken" : "took"
      @flight_list_title = "#{@year} Flight List"
      @superlatives_title = "#{@year} Longest and Shortest Routes"
      @superlatives_title_nav = @superlatives_title.downcase
      @in_text = @year.to_s
      @title = "Flights in #{@year}"
      @meta_description = "Maps and lists of Paul Bogardʼs flights in #{@year}"
    elsif (params[:start_date].present? && params[:end_date].present?)
      @start_date, @end_date = [params[:start_date].to_date, params[:end_date].to_date].sort
      @date_range = @start_date..@end_date
      @date_range_string = "#{FormattedDate.str(@start_date)} to #{FormattedDate.str(@end_date)}"
      @date_range_text = "from #{@date_range_string}"
      @took_taken = @date_range.cover?(Date.today) ? "have taken" : "took"
      @flight_list_title = "Flight List for #{@date_range_string}"
      @superlatives_title = "Longest and Shortest Routes for #{@date_range_string}"
      @superlatives_title_nav = "Longest and shortest routes for #{@date_range_string}"
      @in_text = "this date range"
      @title = "Flights: #{FormattedDate.str(@start_date)} – #{FormattedDate.str(@end_date)}"
      @meta_description = "Maps and lists of Paul Bogardʼs flights from #{@date_range_string}"
    else
      raise ArgumentError.new
    end
    
    flyer_flights = flyer.flights(current_user)
    @flights = flyer_flights.where(departure_date: @date_range).includes(:airline, :origin_airport, :destination_airport, :trip)
    @year_range = flyer_flights.year_range
    @years_with_flights = flyer_flights.years_with_flights
    
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @region = current_region(default: [])
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = @flights.total_distance
      
    # Create comparitive lists of airlines and classes:
    @airports = Airport.visit_table_data(@flights) 
    @airlines = Airline.flight_table_data(@flights, type: :airline) 
    @aircraft_families = AircraftFamily.flight_table_data(@flights)
    @classes = TravelClass.flight_table_data(@flights)
    @new_airports = Airport.new_in_date_range(flyer, current_user, @date_range)
    @new_airlines = Airline.new_in_date_range(flyer, current_user, @date_range)   
    @new_aircraft_families = AircraftFamily.new_in_date_range(flyer, current_user, @date_range)
    @new_classes = TravelClass.new_in_date_range(flyer, current_user, @date_range)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
          
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find any flights in #{@in_text}. Instead, weʼll give you a list of flights."
    redirect_to flights_path
    
  rescue ArgumentError
    flash[:warning] = "We couldn’t understand the dates provided to us. Instead, we’ll give you a list of flights."
    redirect_to flights_path
    
  end
  
  # Shows a table of all {TravelClass travel classes} flown.
  #
  # @return [nil]
  def index_classes    
    @flights = flyer.flights(current_user)
    @sort = Table.sort_parse(params[:sort], :quality, :desc)
    @classes = TravelClass.flight_table_data(@flights, *@sort)    
  end
  
  # Shows details for a particular {TravelClass travel class} and data for all
  # {Flight Flights} flown in that class.
  #
  # {TravelClass Travel class} details:
  # * name
  # * description
  #
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}
  # * the total distance flown
  # * a table of {Airline Airlines}
  # * a table of {AirlinesController#show_operator operators}
  # * a table of {AircraftFamily AircraftFamilies}
  # * the longest and shortest {Flight}
  #
  # @return [nil]
  def show_class
    @logo_used = true
    
    @flights = flyer.flights(current_user).where(travel_class: params[:travel_class]).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @class = params[:travel_class]
    
    @region = current_region(default: [])
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = @flights.total_distance

    # Create comparitive lists of airlines, operators, and aircraft:
    @airlines = Airline.flight_table_data(@flights, type: :airline)
    @operators = Airline.flight_table_data(@flights, type: :operator)
    @aircraft_families = AircraftFamily.flight_table_data(@flights)

    # Create superlatives:
    @route_superlatives = superlatives(@flights)
    
  rescue ActiveRecord::RecordNotFound
    flash[:warning] = "We couldnʼt find any flights in #{@title}. Instead, weʼll give you a list of travel classes."
    redirect_to classes_path
  end

  # Shows a table of all {TailNumber tail numbers} flown.
  #
  # @return [nil]
  def index_tails
      
    @flights = flyer.flights(current_user)
    @sort = Table.sort_parse(params[:sort], :flights, :desc)
    @tail_numbers_table = TailNumber.flight_table_data(@flights, *@sort)
  
    # Find maxima for graph scaling:
    @flights_maximum = @tail_numbers_table.max_by{|i| i[:count]}[:count]
      
  end
  
  # Shows details for a particular {TailNumber tail number} and data for all
  # {Flight Flights} flown on that tail number.
  # 
  # {TailNumber Tail number} details:
  # * the {AircraftFamily aircraft type}
  # * the country registering this tail
  # * a link to {https://flightaware.com/ FlightAware's} live flight tracking for this tail
  # 
  # {Flight} data:
  # * a {FlightsMap}
  # * a table of {Flight Flights}
  # * the total distance flown
  # * a table of {TravelClass travel classes}
  # * a table of {Airline Airlines}
  # * a table of {AirlinesController#show_operator operators}
  # * the longest and shortest {Flight}
  #
  # @return [nil]
  # @see https://flightaware.com/ FlightAware
  def show_tail
    @logo_used = true
    @flights = flyer.flights(current_user).where(tail_number: TailNumber.simplify(params[:tail_number])).includes(:airline, :origin_airport, :destination_airport, :trip)
    raise ActiveRecord::RecordNotFound if @flights.length == 0
    
    @tail_number = TailNumber.format(params[:tail_number])
    
    @region = current_region(default: [])
    @map = FlightsMap.new(@flights, region: @region)
    @total_distance = @flights.total_distance
    
    # Create comparitive list of airlines, operators, and classes:
    @airlines = Airline.flight_table_data(@flights, type: :airline)
    @operators = Airline.flight_table_data(@flights, type: :operator)
    @classes = TravelClass.flight_table_data(@flights)
    
    # Create superlatives:
    @route_superlatives = superlatives(@flights)
        
  rescue ActiveRecord::RecordNotFound
   flash[:warning] = "We couldnʼt find any flights with the tail number #{params[:tail_number]}. Instead, weʼll give you a list of tail numbers."
    redirect_to tails_path
  end
  
  # Shows a form to enter BCBP-formatted {BoardingPass} data for parsing.
  #
  # @return [nil]
  # @see #build_boarding_pass
  # @see #show_boarding_pass
  def input_boarding_pass
  end
  
  # Checks whether a boarding pass is present. Redirects to
  # {#show_boarding_pass} (if present) or {#input_boarding_pass} (if absent).
  #
  # @return [nil]
  # @see #input_boarding_pass
  # @see #show_boarding_pass
  def build_boarding_pass
    if params[:data].present?
      redirect_to show_boarding_pass_path(params[:data])
    else
      flash[:error] = "Boarding pass data cannot be blank."
      redirect_to boarding_pass_path
    end
  end
  
  # Shows parsed BCBP-formatted {BoardingPass} data.
  #
  # @return [nil]
  # @see #input_boarding_pass
  # @see #build_boarding_pass
  def show_boarding_pass
    
    @boarding_pass = BoardingPass.new(params[:data])
    if @boarding_pass.data.dig(:repeated, 0, :mandatory, 42)
      @results = "#{@boarding_pass.data.dig(:repeated, 0, :mandatory, 42, :raw)} #{@boarding_pass.data.dig(:repeated, 0, :mandatory, 43, :raw)} #{@boarding_pass.data.dig(:repeated, 0, :mandatory, 26, :raw)} ✈ #{@boarding_pass.data.dig(:repeated, 0, :mandatory, 38, :raw)}"
    else
      @results = "Results"
    end
    
  end
  
  # Shows a JSON document representing parsed BCBP-formatted {BoardingPass} data.
  #
  # @return [nil]
  def show_boarding_pass_json
    boarding_pass = BoardingPass.new(params[:data])
    if params[:callback]
      render :json => boarding_pass.data, :callback => params[:callback]
    else
      render :json => boarding_pass.data
    end
  end

  # Shows a set of forms to allow the user to choose how they will enter their
  # new flight. Allows the user to provide an Apple Wallet {PKPass}, to provide
  # IATA BCBP-formatted {BoardingPass} barcode data, to provide an {Airline}
  # and flight number to look up with {FlightXML}, or to choose to manually
  # enter all flight data. 
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  # @see https://developer.apple.com/documentation/passkit/wallet Wallet | Apple Developer Documentation
  # @see https://www.iata.org/whatwedo/stb/Documents/BCBP-Implementation-Guide-5th-Edition-June-2016.pdf
  #   IATA Bar Coded Boarding Pass (BCBP) Implementation Guide
  # @see https://flightaware.com/commercial/flightxml/documentation2.rvt FlightXML 2.0 Documentation
  def new_flight_menu
    clear_new_flight_variables
    
    # Determine an appropriate trip to use:
    begin
      @trip = Trip.find(params[:trip_id])
    rescue ActiveRecord::RecordNotFound
      if Trip.where(hidden: true).any?
        @trip = Trip.where(hidden: true).order(:created_at).last
      elsif Trip.any?
        @trip = Trip.order(:created_at).last
      else
        flash[:warning] = "You have no trips to put a flight in, so we can’t create a new flight. Please create a trip."
        redirect_to new_trip_path
      end
    end
    empty_trips = Trip.with_no_flights.map{|trip| [trip.name, trip.id]}
    @trips = empty_trips.concat(Trip.with_departure_dates(current_user, current_user).reverse.map{|trip| ["#{trip.name} / #{FormattedDate.str(trip.departure_date)}", trip.id]})
    
    # Get PKPasses:
    check_email_for_boarding_passes
    @passes = PKPass.pass_summary_list
        
  end
  
  # Changes the {Trip} form field on the {#new_flight_menu}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def change_trip
    redirect_to new_flight_menu_path(trip_id: params[:trip_id])
  end
  
  # Shows a form to add a {Flight} to a specified {Trip}. This form is
  # prepopulated with any known {PKPass}, {BoardingPass}, and {FlightXML} data extracted
  # from information provided in the {#new_flight_menu}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  # @see https://developer.apple.com/documentation/passkit/wallet Wallet | Apple Developer Documentation
  # @see https://www.iata.org/whatwedo/stb/Documents/BCBP-Implementation-Guide-5th-Edition-June-2016.pdf
  #   IATA Bar Coded Boarding Pass (BCBP) Implementation Guide
  # @see https://flightaware.com/commercial/flightxml/documentation2.rvt FlightXML 2.0 Documentation
  def new

    # Check if this page was loaded directly from a form submission. If so,
    # clear out the session variables. This keeps extraneous data from spilling
    # over if a user submits one new flight form, clicks back to get to the
    # menu, and then submits a different new flight form.
    clear_new_flight_variables if params[:clear_session]
    
    # Save form parameters to session:
    session[:new_flight] ||= Hash.new
    session[:new_flight][:warnings] = Array.new
    session_params = [:airline_icao, :boarding_pass_data, :codeshare_airline_icao, :codeshare_flight_number, :departure_utc, :destination_airport_icao, :fa_flight_id, :flight_number, :origin_airport_icao, :pk_pass_id, :trip_id]
    session_params.map{ |p| session[:new_flight][p] = params[p] if params[p] }
    session[:new_flight][:completed_flight_xml] = true if params[:completed_flight_xml]
    session[:new_flight][:departure_date] = params[:departure_date].to_date if params[:departure_date]
    session[:new_flight][:departure_utc] = params[:departure_utc].to_time(:utc) if params[:departure_utc]
    
    # Locate trip and create flight:
    trip = Trip.find(session[:new_flight][:trip_id])
    @flight = trip.flights.new
    
    # Get flight data from PKPass:
    if (session[:new_flight][:completed_pk_pass] != true && pk_pass = PKPass.find_by(id: session[:new_flight][:pk_pass_id]))
      pk_pass_values = pk_pass.form_values
      session[:new_flight][:boarding_pass_data] = pk_pass_values[:boarding_pass_data]
      session[:new_flight][:departure_utc] = pk_pass_values[:departure_utc] if pk_pass_values[:departure_utc]
    end
    session[:new_flight][:completed_pk_pass] = true
  
    # Get flight data from BCBP:
    if (session[:new_flight][:completed_bcbp] != true && session[:new_flight][:boarding_pass_data])
      boarding_pass = BoardingPass.new(session[:new_flight][:boarding_pass_data], interpretations: false)
      if boarding_pass.data.present?
        boarding_pass_values = boarding_pass.form_values(session[:new_flight][:departure_utc]) || Hash.new
        session[:new_flight].merge!(boarding_pass_values.reject{ |k,v| v.nil? })
      else
        session[:new_flight][:warnings].push(BoardingPass::ERROR)
      end
    end
    session[:new_flight][:completed_bcbp] = true
  
    # Get flight data from FlightXML:
    if (session[:new_flight][:completed_flight_xml] != true)
      if session[:new_flight][:fa_flight_id]
        set_flight_xml_data(session[:new_flight][:fa_flight_id])
      elsif session[:new_flight][:flight_number]
        session[:new_flight][:airline_icao] ||= Airline.convert_iata_to_icao(session[:new_flight][:airline_iata], false)
        if session[:new_flight][:airline_icao]
          session[:new_flight][:ident] = [session[:new_flight][:airline_icao],session[:new_flight][:flight_number]].join
          if session[:new_flight][:departure_utc] && fa_flight_id = FlightXML.get_flight_id(session[:new_flight][:ident], session[:new_flight][:departure_utc])
            set_flight_xml_data(fa_flight_id)
          else
            @fa_flights = FlightXML.flight_lookup(session[:new_flight][:ident])
            if @fa_flights && @fa_flights.any?
              airports = (@fa_flights.map{|f| f[:origin]} | @fa_flights.map{|f| f[:destination]})
              @timezones = FlightXML.airport_timezones(airports)
              render "flightxml_select_flight"
              return
            else
              session[:new_flight][:warnings].push(FlightXML::ERROR + " (Searched for #{session[:new_flight][:ident]})")
            end
          end
        end
      end
    end
    
  
    # Convert IATA and ICAO codes to database IDs:
    id_fields = get_or_create_ids_from_codes
    return if id_fields.nil?
    session[:new_flight].merge!(id_fields) if id_fields
    session[:new_flight][:completed_flight_xml] = true # Do this after codes so we can look up new codes if need be
  
    # Guess trip section:
    session[:new_flight][:trip_section] = trip.estimated_trip_section(session[:new_flight][:departure_utc])
  
    # Guess origin airport (if not set) from last destination airport:
    session[:new_flight][:origin_airport_id] ||= Flight.chronological.last.destination_airport_id
  
    # Guess departure date and departure UTC (if not set) from the current time:
    now = Time.now.utc
    session[:new_flight][:departure_utc] ||= now
    session[:new_flight][:departure_date] ||= now.to_date

    # Render new flight form:
    session[:new_flight][:warnings].each{|w| add_message(:warning, w) }
      
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "We could not find a trip with an ID of #{params[:trip_id]}. Please select another trip."
    redirect_to new_flight_menu_path
    
  end
  
  # Creates a new {Flight}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def create
    clear_new_flight_variables
    @flight = Trip.find(params[:flight][:trip_id]).flights.new(flight_params)
    if @flight.save
      flash[:success] = "Successfully added #{@flight.airline.airline_name} #{@flight.flight_number}."
      if (@flight.tail_number.present? && Flight.where(:tail_number => @flight.tail_number).count > 1)
        flash[:success] += " Youʼve had prior flights on this tail!"
      end
      if (@flight.departure_date.to_time - @flight.departure_utc.to_time).to_i.abs > 60*60*24*2
        flash[:warning] = ActionController::Base.helpers.sanitize("Your departure date and UTC time are more than a day apart &ndash; are you sure theyʼre correct?")
      end
      # If pass exists, delete pass 
      if params[:flight][:pk_pass_id]
        pass = PKPass.find_by(id: params[:flight][:pk_pass_id])
        pass.destroy if pass
      end
      redirect_to @flight
    else
      @title = "New Flight"
      render "new"
    end
  end
  
  # Shows a form to edit an existing {Flight}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def edit
    @flight = Flight.find(params[:id])
  end
  
  # Updates an existing {Flight}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def update
    @flight = Flight.find(params[:id])
    if @flight.update_attributes(flight_params)
      flash[:success] = "Successfully updated flight."
      if (@flight.tail_number.present? && Flight.where(:tail_number => @flight.tail_number).count > 1)
        flash[:success] += " You’ve had prior flights on this tail!"
      end
      if (@flight.departure_date.to_time - @flight.departure_utc.to_time).to_i.abs > 60*60*24*2
        flash[:warning] = ActionController::Base.helpers.sanitize("Your departure date and UTC time are more than a day apart &ndash; are you sure they’re correct?")
      end
      @pass = PKPass.find_by(id: params[:flight][:pass_id])
      @pass.destroy if @pass
      
      redirect_to @flight
    else
      render "edit"
    end
  end
  
  # Deletes an existing {Flight}.
  #
  # This action can only be performed by a verified user.
  #
  # @return [nil]
  def destroy
    flight = Flight.find(params[:id])
    trip = flight.trip
    flight.destroy
    flash[:success] = "Flight destroyed."
    redirect_to trip
  end
    
  private
    
  # Clears all session variables associated with creating a new flight.
  #
  # @return [Hash]
  def clear_new_flight_variables
    session[:new_flight] = Hash.new
  end
  
  def flight_params
    params.require(:flight).permit(:aircraft_family_id, :aircraft_name, :airline_id, :boarding_pass_data, :codeshare_airline_id, :codeshare_flight_number, :comment, :departure_date, :departure_utc, :destination_airport_id, :fleet_number, :flight_number, :operator_id, :origin_airport_id, :tail_number, :travel_class, :trip_id, :trip_section)
  end
    
  # Uses ICAO or IATA codes in session[:new_flights] to determine
  # {AircraftFamily}, {Airline}, and {Airport} IDs, returning them in a hash.
  # If any ICAO or IATA codes are not found, this method redirects to a form
  # allowing the user to create new {AircraftFamily AircraftFamilies}, {Airline
  # Airlines}, or {Airport Airports} as needed.
  #
  # @return [Hash] a hash of {AircraftFamily}, {Airline}, and {Airport} IDs
  def get_or_create_ids_from_codes
    
    ids = Hash.new
          
    # AIRPORTS
    
    if session[:new_flight][:origin_airport_id].blank? && (session[:new_flight][:origin_airport_icao] || session[:new_flight][:origin_airport_iata])
      if session[:new_flight][:origin_airport_icao] && origin_airport = Airport.find_by(icao_code: session[:new_flight][:origin_airport_icao])
        ids.store(:origin_airport_id, origin_airport.id)
      elsif session[:new_flight][:origin_airport_iata] && origin_airport = Airport.find_by(iata_code: session[:new_flight][:origin_airport_iata])
        ids.store(:origin_airport_id, origin_airport.id)
      else
        input_new_undefined_airport(session[:new_flight][:origin_airport_iata], session[:new_flight][:origin_airport_icao]) and return nil
      end
    end
    
    if session[:new_flight][:destination_airport_id].blank? && (session[:new_flight][:destination_airport_icao] || session[:new_flight][:destination_airport_iata])
      if session[:new_flight][:destination_airport_icao] && destination_airport = Airport.find_by(icao_code: session[:new_flight][:destination_airport_icao])
        ids.store(:destination_airport_id, destination_airport.id)
      elsif session[:new_flight][:destination_airport_iata] && destination_airport = Airport.find_by(iata_code: session[:new_flight][:destination_airport_iata])
        ids.store(:destination_airport_id, destination_airport.id)
      else
        input_new_undefined_airport(session[:new_flight][:destination_airport_iata], session[:new_flight][:destination_airport_icao]) and return nil
      end
    end
    
    # AIRCRAFT FAMILIES
    
    if session[:new_flight][:aircraft_family_id].blank? && session[:new_flight][:aircraft_family_icao]
      if session[:new_flight][:aircraft_family_icao] && aircraft_family = AircraftFamily.find_by(icao_aircraft_code: session[:new_flight][:aircraft_family_icao])
        ids.store(:aircraft_family_id, aircraft_family.id)
      else
        input_new_undefined_aircraft_family(session[:new_flight][:aircraft_family_icao]) and return nil
      end
    end
    
    # AIRLINES
    
    if session[:new_flight][:airline_id].blank? && (session[:new_flight][:airline_icao] || session[:new_flight][:airline_iata])
      if session[:new_flight][:airline_icao] && airline = Airline.find_by(icao_airline_code: session[:new_flight][:airline_icao])
        ids.store(:airline_id, airline.id)
      elsif session[:new_flight][:airline_iata] && airline = Airline.find_by(iata_airline_code: session[:new_flight][:airline_iata])
        ids.store(:airline_id, airline.id)
      else
        input_new_undefined_airline(session[:new_flight][:airline_iata], session[:new_flight][:airline_icao]) and return nil
      end
    end
    
    if session[:new_flight][:operator_id].blank? && session[:new_flight][:operator_icao]
      if session[:new_flight][:operator_icao] && operator = Airline.find_by(icao_airline_code: session[:new_flight][:operator_icao])
        ids.store(:operator_id, operator.id)
      else
        input_new_undefined_airline(nil, session[:new_flight][:operator_icao]) and return nil
      end
    end
    
    if session[:new_flight][:codeshare_airline_id].blank? && session[:new_flight][:codeshare_airline_icao] || session[:new_flight][:codeshare_airline_iata]
      if session[:new_flight][:codeshare_airline_icao] && codeshare_airline = Airline.find_by(icao_airline_code: session[:new_flight][:codeshare_airline_icao])
        ids.store(:codeshare_airline_id, codeshare_airline.id)
      elsif session[:new_flight][:codeshare_airline_iata] && codeshare_airline = Airline.find_by(iata_airline_code: session[:new_flight][:codeshare_airline_iata])
        ids.store(:codeshare_airline_id, codeshare_airline.id)
      else
        input_new_undefined_airline(session[:new_flight][:codeshare_airline_iata], nil) and return nil
      end
    end
                      
    return ids
    
  end
  
  # Shows a form to create a new {Airport} from an unrecognized IATA or ICAO
  # airport code in {PKPass}, {BoardingPass}, or {FlightXML} data.
  #
  # @param iata [String] an IATA airport code
  # @param icao [String] an ICAO airport code
  # @return [nil]
  def input_new_undefined_airport(iata, icao)
    @airport = Airport.new
    @lookup_fields = {iata_code: iata, icao_code: icao}
    session[:form_location] = Rails.application.routes.recognize_path(request.original_url)
    render "new_undefined_airport" and return true
  end
  
  # Shows a form to create a new {AircraftFamily} from an unrecognized ICAO
  # aircraft type code in {PKPass}, {BoardingPass}, or {FlightXML} data.
  #
  # @param icao [String] an ICAO aircraft type code
  # @return [nil]
  def input_new_undefined_aircraft_family(icao)
    @aircraft_family = AircraftFamily.new
    @lookup_fields = {icao_code: icao}
    session[:form_location] = Rails.application.routes.recognize_path(request.original_url)
    render "new_undefined_aircraft_family" and return true
  end
  
  # Shows a form to create a new {Airline} from an unrecognized IATA or ICAO
  # airline code in {PKPass}, {BoardingPass}, or {FlightXML} data.
  #
  # @param iata [String] an IATA airline code
  # @param icao [String] an ICAO airline code
  # @return [nil]
  def input_new_undefined_airline(iata, icao)
    @airline = Airline.new
    @lookup_fields = {iata_code: iata, icao_code: icao}
    session[:form_location] = Rails.application.routes.recognize_path(request.original_url)
    render "new_undefined_airline" and return true
  end
  
  # Add non-blank {FlightXML} data to the {#new} {Flight} form prepopulated data hash.
  # 
  # @return [Hash]
  def set_flight_xml_data(fa_flight_id)
    flightxml_data = FlightXML.form_values(fa_flight_id)
    if flightxml_data
      session[:new_flight].merge!(flightxml_data.reject{ |k,v| v.nil? })
    else
      if session[:new_flight][:ident] && session[:new_flight][:departure_utc]
        session[:new_flight][:warnings].push(FlightXML::ERROR + " (Searched for #{session[:new_flight][:ident]} / #{session[:new_flight][:departure_utc].strftime("%-d %b %Y %R")} UTC)")
      else
        session[:new_flight][:warnings].push(FlightXML::ERROR)
      end
    end
  end
  
end
