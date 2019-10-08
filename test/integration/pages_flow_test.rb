require "test_helper"

class PagesFlowTest < ActionDispatch::IntegrationTest
  
  test "can see home" do
    get "/"
    assert_response :success
    assert_select "div.message-info", {count: 0, text: /Active Trip/}, "This view must not list an active trip"
    assert_select "a:match('href', ?)", "/new-flight-menu", {count: 0}, "This view must not show a link to import boarding passes"
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
    # At least one PKPass must be present for this test to succeed.
    log_in_as users(:user_one)
    get "/"
    assert_response :success
    assert_select "div.message-info", /Active Trip/, "This view must list an active trip"
    assert_select "a:match('href', ?)", "/new-flight-menu", {}, "This view must show a link to import boarding passes"
  end

  test "can see letsencrypt" do
    key = "C_EF567890"
    cached_lets_encrypt_key = ENV["LETS_ENCRYPT_KEY"]
    ENV["LETS_ENCRYPT_KEY"] = key

    get "/.well-known/acme-challenge/ABCD1234"
    assert_response :success
    assert_equal "text/plain", response.content_type
    assert_equal key, response.body

    ENV["LETS_ENCRYPT_KEY"] = cached_lets_encrypt_key
  end

end
