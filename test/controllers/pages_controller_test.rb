require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  
  airport_options = "b:disc5:black"
  query           = "DAY-DFW/ORD"
  
  test "should get home" do
    get root_url
    assert_response :success
  end
  
  test "should get proxy image with correct key" do
    get gcmap_image_url(airport_options, query.gsub('/','_'), Map.hash_image_query(query))
    assert_response :success
  end
  
  test "should reject proxy image with incorrect key" do
    bad_check = "FOO"
    assert_raises(ActionController::RoutingError) do
      get gcmap_image_url(airport_options, query.gsub('/','_'), bad_check)
    end
  end
  
end