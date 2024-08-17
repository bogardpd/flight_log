require 'test_helper'

class MapFlowsTest < ActionDispatch::IntegrationTest
  
  def setup
    stub_aero_api4_get_timeout
    @extensions = {
      gpx:     "application/gpx+xml",
      kml:     "application/vnd.google-earth.kml+xml",
      geojson: "application/geo+json",
      graphml: "application/xml",
      html:    "text/html",
    }
  end

  test "render FlightsMap extensions" do
    get flights_path(map_id: :flights_map, extension: :gpx)
    assert_response :success
    assert_equal(@extensions[:gpx], content_type)

    get flights_path(map_id: :flights_map, extension: :kml)
    assert_response :success
    assert_equal(@extensions[:kml], content_type)

    get flights_path(map_id: :flights_map, extension: :geojson)
    assert_response :success
    assert_equal(@extensions[:geojson], content_type)

    get flights_path(map_id: :flights_map, extension: :graphml)
    assert_response :success
    assert_equal(@extensions[:graphml], content_type)
  end

  test "render SingleFlightMap extensions" do
    route = routes(:route_dfw_ord)

    get show_route_path(route.airport1.slug, route.airport2.slug, map_id: :route_map, extension: :gpx)
    assert_response :success
    assert_equal(@extensions[:gpx], content_type)

    get show_route_path(route.airport1.slug, route.airport2.slug, map_id: :route_map, extension: :kml)
    assert_response :success
    assert_equal(@extensions[:kml], content_type)

    get show_route_path(route.airport1.slug, route.airport2.slug, map_id: :route_map, extension: :geojson)
    assert_response :success
    assert_equal(@extensions[:geojson], content_type)

    get show_route_path(route.airport1.slug, route.airport2.slug, map_id: :route_map, extension: :graphml)
    assert_response :success
    assert_equal(@extensions[:html], content_type) # This map type does not support graphml.
  end

  test "render HighlightedRoutesMap extensions" do
    route = routes(:route_dfw_ord)

    get show_route_path(route.airport1.slug, route.airport2.slug, map_id: :sections_map, extension: :gpx)
    assert_response :success
    assert_equal(@extensions[:gpx], content_type)

    get show_route_path(route.airport1.slug, route.airport2.slug, map_id: :sections_map, extension: :kml)
    assert_response :success
    assert_equal(@extensions[:kml], content_type)

    get show_route_path(route.airport1.slug, route.airport2.slug, map_id: :sections_map, extension: :geojson)
    assert_response :success
    assert_equal(@extensions[:geojson], content_type)

    get show_route_path(route.airport1.slug, route.airport2.slug, map_id: :sections_map, extension: :graphml)
    assert_response :success
    assert_equal(@extensions[:graphml], content_type)
  end

  test "render AirportsMap extensions" do
    get airports_path(map_id: :airports_map, extension: :gpx)
    assert_response :success
    assert_equal(@extensions[:gpx], content_type)

    get airports_path(map_id: :airports_map, extension: :kml)
    assert_response :success
    assert_equal(@extensions[:kml], content_type)

    get airports_path(map_id: :airports_map, extension: :geojson)
    assert_response :success
    assert_equal(@extensions[:geojson], content_type)

    get airports_path(map_id: :airports_map, extension: :graphml)
    assert_response :success
    assert_equal(@extensions[:graphml], content_type)
  end

  test "render AirportFrequencyMap extensions" do
    get airports_path(map_id: :frequency_map, extension: :gpx)
    assert_response :success
    assert_equal(@extensions[:gpx], content_type)

    get airports_path(map_id: :frequency_map, extension: :kml)
    assert_response :success
    assert_equal(@extensions[:kml], content_type)

    get airports_path(map_id: :frequency_map, extension: :geojson)
    assert_response :success
    assert_equal(@extensions[:geojson], content_type)

    get airports_path(map_id: :frequency_map, extension: :graphml)
    assert_response :success
    assert_equal(@extensions[:graphml], content_type)
  end

  private

  def content_type
    return response.content_type.split(";")[0]
  end

end