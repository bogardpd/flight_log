require "test_helper"

class PageFlowsTest < ActionDispatch::IntegrationTest
  
  ##############################################################################
  # Tests for Spec > Pages (Views) > Home                                      #
  ##############################################################################

  test "can see home" do
    get(root_path)
    assert_response(:success)

    assert_select("div:match('id',?)", /message-active-trip-\d+/, {count: 0}, "This view shall not list an active trip")
    assert_select("div#message-boarding-passes-available-for-import", {count: 0}, "This view shall not show a link to import boarding passes")
    assert_select("img.map", {}, "This view shall contain a map")
    assert_select("a:match('href', ?)", "/flights", {}, "This view shall contain a link to Index Flights")
    assert_select("span.summary-total", {}, "This view shall contain a count of flights")
    assert_select("h2", "Top Airports")
    assert_select("h2", "Top Airlines")
    assert_select("h2", "Top Routes")
    assert_select("h2", "Top Aircraft")
    assert_select("h2", "Top Tails")
    assert_select("h2", "Superlatives")
  end

  test "can see active trips on home when logged in" do
    # At least one PKPass shall be present for this test to succeed.
    hidden_trip = trips(:trip_hidden)
    log_in_as(users(:user_one))
    get(root_path)
    assert_response(:success)

    assert_select("div#message-active-trip-#{hidden_trip.id}", {}, "This view shall list an active trip")
    assert_select("div#message-boarding-passes-available-for-import", {}, "This view shall show a link to import boarding passes")
  end

  ##############################################################################
  # Other tests                                                                #
  ##############################################################################

  test "can see letsencrypt" do
    key = "C_EF567890"
    cached_lets_encrypt_key = ENV["LETS_ENCRYPT_KEY"]
    ENV["LETS_ENCRYPT_KEY"] = key

    get("/.well-known/acme-challenge/ABCD1234")
    assert_response(:success)
    assert_equal("text/plain", response.content_type)
    assert_equal(key, response.body)

    ENV["LETS_ENCRYPT_KEY"] = cached_lets_encrypt_key
  end

end
