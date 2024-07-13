// Functions for working with mapboxgl maps.

function mapCenterZoom(geojson_data) {

  // Get MultiLineString features.
  let features = geojson_data['features'];
  let routes = features.filter(r => r['geometry']['type'] == 'MultiLineString');
  if (routes.length == 0) {
      return {center: [0, 20], zoom: 0.5};
  }

  // Generate Map of longitudes and their changes in count.
  let hasAirportAt180 = false;
  let changes = new Map();
  routes.forEach((route) => {
    let multiline = route['geometry']['coordinates'];
    multiline.forEach((line) => {
      if (line.length > 0) {
        lonRange = [line[0][0], line[line.length - 1][0]].sort(function(a,b) {return a - b});
        changes.set(lonRange[0], changes.has(lonRange[0]) ? changes.get(lonRange[0]) + 1 : 1);
        changes.set(lonRange[1], changes.has(lonRange[1]) ? changes.get(lonRange[1]) - 1 : -1);
        if (multiline.length == 1 && (lonRange[0] == -180 || lonRange[1] == 180)) {
            hasAirportAt180 = true;
        }
      }
    });
  })

  // Generate map of starting (westernmost) longitudes and their total route count.
  let longitudes = Array.from(changes.keys()).sort(function(a,b) {return a - b});
  let currentCount = 0
  let lonRouteCount = new Map();
  longitudes.forEach((lon) => {
    currentCount = currentCount + changes.get(lon);
    lonRouteCount.set(lon, currentCount);
  });

  // Remove antemeridian if no airports are exactly at longitude 180.
  if (!hasAirportAt180) {
    if (longitudes[0] == -180) {
      longitudes.splice(0, 1);
      lonRouteCount.delete(-180);
    }
    if (longitudes[longitudes.length - 1] == 180) {
      longitudes.splice(longitudes.length - 1, 1);
      lonRouteCount.delete(180);
    }
  }

  // Create array of [longitude, width, routeCount] arrays.
  let lonStartValues = [];
  for (let i = 0; i < longitudes.length; i++) {
    let width = (i == longitudes.length - 1) ? longitudes[0] + 360 - longitudes[i] : longitudes[i + 1] - longitudes[i];
    lonStartValues.push([longitudes[i], width, lonRouteCount.get(longitudes[i])]);
  }

  // Select regions with lowest routeCounts, then sort by width descending.
  lonStartValues = lonStartValues.filter(l => l[2] == Math.min(...lonRouteCount.values()))
  lonStartValues = lonStartValues.sort(function(a, b) {return b[1] - a[1]});

  // Get center of of the widest of the lowest routeCount regions.
  console.log(lonStartValues);
  let lonCenter = lonStartValues[0][0] + (lonStartValues[0][1] / 2) + 180;
  while (lonCenter >= 180) {
    lonCenter = lonCenter - 360;
  }

  return {center: [lonCenter, 20], zoom: 0.5};
};
