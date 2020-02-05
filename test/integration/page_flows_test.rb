require "test_helper"

class PageFlowsTest < ActionDispatch::IntegrationTest

  def setup
    @airport_options = "b:disc5:black"
    @query           = "DAY-DFW/ORD"
  end
  
  ##############################################################################
  # Tests for Spec > Pages (Views) > Home                                      #
  # Tests for routes/route_superlatives_table partial                          #
  ##############################################################################

  test "can see home when not logged in" do
    stub_flight_xml_get_wsdl
    stub_flight_xml_post_timeout

    get(root_path)
    assert_response(:success)
    verify_absence_of_hidden_data

    assert_select("div:match('id',?)", /message-active-trip-\d+/, {count: 0}, "This view shall not list an active trip")
    assert_select("div#message-boarding-passes-available-for-import", {count: 0}, "This view shall not show a link to import boarding passes")
    
    assert_select("img.map", {}, "This view shall contain a map")
    assert_select("a:match('href', ?)", "/flights", {}, "This view shall contain a link to Index Flights")
    assert_select("span#summary-flight-total[data-total=?]", visitor_flights.size.to_s, {}, "This view shall contain a count of flights")
    
    assert_select("table#top-airports-table")
    assert_select("table#top-airlines-table")
    assert_select("table#top-routes-table")
    assert_select("table#top-aircraft-table")
    assert_select("table#top-tail-numbers-table")
    assert_select("table#superlatives-table")
  end

  test "can see active trips on home when logged in" do
    # At least one PKPass must be present for this test to succeed.

    stub_flight_xml_get_wsdl
    stub_flight_xml_post_timeout

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
    assert_equal("text/plain", response.media_type)
    assert_equal(key, response.body)

    ENV["LETS_ENCRYPT_KEY"] = cached_lets_encrypt_key
  end

  test "proxy image accepts correct key" do
    stub_gcmap_get_map

    get(gcmap_image_url(@airport_options, @query.gsub('/','_'), Map.hash_image_query(@query)))
    assert_response(:success)
  end
  
  test "proxy image rejects incorrect key" do
    bad_check = "FOO"
    assert_raises(ActionController::RoutingError) do
      get(gcmap_image_url(@airport_options, @query.gsub('/','_'), bad_check))
    end
  end

end
