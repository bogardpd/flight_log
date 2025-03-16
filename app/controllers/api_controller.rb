class ApiController < ApplicationController
  before_action :api_key_user, except: [:index]

  AUTHENTICATION_ERROR = {error: "Invalid API key. Provide a valid 'api-key' in the header."}

  # Renders the index page, showing basic API documentation.
  #
  # @return [nil]
  def index
  end

  # Provides a summary of the user's flight counts and distances for the year.
  #
  # @return [JSON] the user's annual flight summary
  def annual_flight_summary
    render(json: JSON.generate([]), content_type: 'application/json')
  end

  # Provides the last 10 days of flights for the user.
  #
  # @return [JSON] the most recent flights for the user
  def recent_flights
    flights = flyer.flights(@api_key_user).where(departure_utc: 10.days.ago.utc..).order(departure_utc: :desc)
    data = flights.map{|f| {departure_utc: f.departure_utc.iso8601, fh_id: f.id, fa_flight_id: f.fa_flight_id}}
    render(json: JSON.generate(data), content_type: 'application/json')
  end

  private

  # Returns the {User} for the provided API key. If the API key is invalid, an
  # error message is returned.
  #
  # @return [User] the {User} for the provided API key
  def api_key_user
      @api_key_user = User.find_by_api_key(request.headers['api-key'])
      if @api_key_user.nil?
        render(json: JSON.generate(AUTHENTICATION_ERROR), content_type: 'application/json', status: 403)
      end
      return @api_key_user
  end

end
