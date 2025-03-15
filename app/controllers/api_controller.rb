class ApiController < ApplicationController
  before_action :api_key_user, only: [:recent_flights]

  AUTHENTICATION_ERROR = {error: "Invalid API key. Provide a valid 'api-key' in the header."}

  def index
  end

  # Returns the last 10 days of flights for the user.
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
