class ApiController < ApplicationController
  before_action :api_key_user, only: [:recent_flights]

  AUTHENTICATION_ERROR = {error: "Invalid API key. Provide a valid 'api-key' in the header."}

  def index
  end

  def recent_flights
    data = {
      success: true,
    }
    render(json: JSON.generate(data), content_type: 'application/json')
  end

  private

  def api_key_user
      @api_key_user = User.find_by_api_key(request.headers['api-key'])
      if @api_key_user.nil?
        render(json: JSON.generate(AUTHENTICATION_ERROR), content_type: 'application/json', status: 403)
      end
      return @api_key_user
  end

end
