require "test_helper"

class GreatCircleTest < ActiveSupport::TestCase

  def test_gc_route_coords_without_antimeridian
    lon_range = (-5..5)
    p1 = Coordinate.new(0,lon_range.begin)
    p2 = Coordinate.new(0,lon_range.end)
    path = GreatCircle.gc_route_coords(p1, p2, 1.0)
    assert_equal path[0].size, lon_range.count
  end

  def test_gc_route_coords_with_antimeridian
    lon_range_e = (170..180)
    lon_range_w = (-180..-175)
    p1 = Coordinate.new(0,lon_range_e.begin)
    p2 = Coordinate.new(0,lon_range_w.end)
    path = GreatCircle.gc_route_coords(p1, p2, 1.0)
    assert_equal path[0].size, lon_range_e.count
    assert_equal path[1].size, lon_range_w.count
  end

end