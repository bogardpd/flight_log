require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  
  def setup
    @airport_options = "b:disc5:black"
    @query           = "DAY-DFW/ORD"
  end
  
  def test_root_path_success
    get root_url
    assert_response :success
  end
  
  def test_proxy_image_accepts_correct_key
    get gcmap_image_url(@airport_options, @query.gsub('/','_'), Map.hash_image_query(@query))
    assert_response :success
  end
  
  def test_proxy_image_rejects_incorrect_key
    bad_check = "FOO"
    assert_raises(ActionController::RoutingError) do
      get gcmap_image_url(@airport_options, @query.gsub('/','_'), bad_check)
    end
  end
  
end