require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # driven_by :selenium, using: :headless_chrome, screen_size: [820, 1200]
  driven_by :selenium, using: :chrome, screen_size: [820, 1200]

  # Sets up stub requests used by multiple tests
  def stub_system_common_requests
    stub_request(:get, /www.gcmap.com/).to_return(status: 200, body: "", headers: {})
    stub_request(:head, /amazonaws.com\/pbogardcom-images/).to_return(status: 200, body: "", headers: {})

    stub_request(:get, "https://flightxml.flightaware.com/soap/FlightXML2/wsdl").
      with(
        headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>/Basic \w*==/,
        'User-Agent'=>'Ruby'
        }).
      to_return(status: 200, body: "", headers: {})
  end
  
end
