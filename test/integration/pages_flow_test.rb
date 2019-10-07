require "test_helper"

class PagesFlowTest < ActionDispatch::IntegrationTest
  
  test "can see home" do
    get "/"
    assert_response :success
    assert_select "div.message-info", {count: 0, text: /Active Trip/}, "This view must not list an active trip"
    assert_select "img.map", {}, "This view must contain a map"
    assert_select "a:match('href', ?)", "/flights", {}, "This view must contain a link to Index Flights"
    assert_select "span.summary-total", {}, "This view must contain a count of flights"
    assert_select "h2", "Top Airports"
    assert_select "h2", "Top Airlines"
    assert_select "h2", "Top Routes"
    assert_select "h2", "Top Aircraft"
    assert_select "h2", "Top Tails"
    assert_select "h2", "Superlatives"
  end

  test "can see active trips on home when logged in" do
    # At least one Trip must have hidden: true for this test to succeed.
    log_in_as users(:user_one)
    get "/"
    assert_response :success
    assert_select "div.message-info", /Active Trip/, "This view must list an active trip"
  end

end
