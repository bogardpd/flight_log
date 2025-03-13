class ApiController < ApplicationController

  def index
  end

  def recent_flights
    data = JSON.generate({success: true})
    render(json: data, content_type: 'application/json')
  end

end
