require "test_helper"

class PageFlowsTest < ActionDispatch::IntegrationTest

  def setup
    @airport_options = "b:disc5:black"
    @query           = "DAY-DFW/ORD"

    @extension_types = {
      'geojson' => "application/geo+json",
      'gpx'     => "application/gpx+xml",
      'graphml' => "application/xml",
      'kml'     => "application/vnd.google-earth.kml+xml",
    }
  end

  ##############################################################################
  # Tests for Spec > Pages (Views) > Home                                      #
  # Tests for routes/route_superlatives_table partial                          #
  ##############################################################################

  test "cannot see home when not logged in" do
    stub_aero_api4_get_timeout
    get(root_path)
    assert_redirected_to(login_path)
  end

  test "can see active trips on home when logged in" do
    # At least one PKPass must be present for this test to succeed.

    stub_aero_api4_get_timeout

    hidden_trip = trips(:trip_hidden)
    log_in_as(users(:user_one))
    get(root_path)
    assert_response(:success)

    assert_select("div#message-active-trip-#{hidden_trip.id}", {}, "This view shall list an active trip")
    assert_select("div#message-boarding-passes-available-for-import", {}, "This view shall show a link to import boarding passes")
  end

  test "can see home alternate map formats" do
    stub_aero_api4_get_timeout

    log_in_as(users(:user_one))
    @extension_types.each do |extension, type|
      get(root_path(map_id: "flights_map", extension: extension))
      assert_response(:success)
      assert_equal(type, response.media_type)
    end
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

end
