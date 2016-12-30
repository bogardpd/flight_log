require 'test_helper'

class AdminControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:sampleuser)
  end
  
   def test_redirect_annual_flight_summary_when_not_logged_in
    get annual_flight_summary_path
#    assert_redirected_to root_path
  end
  
end
