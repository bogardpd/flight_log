require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  
  def setup
    @airport_options = "b:disc5:black"
    @query           = "DAY-DFW/ORD"
  end
  
  test "proxy_image_accepts_correct_key" do
    get gcmap_image_url(@airport_options, @query.gsub('/','_'), Map.hash_image_query(@query))
    assert_response :success
  end
  
  test "proxy_image_rejects_incorrect_key" do
    bad_check = "FOO"
    assert_raises(ActionController::RoutingError) do
      get gcmap_image_url(@airport_options, @query.gsub('/','_'), bad_check)
    end
  end
  
end