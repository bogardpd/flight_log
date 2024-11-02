// Functions for working with mapboxgl maps.

function populateMapboxGLMap(mapID, mapData, mapType) {
  // Accepts GeoJSON mapData and a mapType, and populates a mapID div.
  
  const mapPosition = mapCenterZoom(mapData);
  const mapContainer = 'mapbox_' + mapID;
  
  const map = new mapboxgl.Map({
    container: mapContainer,
    style: 'mapbox://styles/bogardpd/cly0gib62008301p82kk64np1', // Light Terrain - Flight Historian
    center: mapPosition['center'],
    zoom: mapPosition['zoom'],
  });

  map.on('load', () => {
     // Load data.
     map.addSource('flights', {
      'type': 'geojson',
      'data': mapData,
      'generateId': true,
    })

    // Add routes.
    map.addLayer({
      'id': 'routes',
      'type': 'line',
      'source': 'flights',
      'filter': ['==', '$type', 'LineString'],
      'paint': {
        'line-width': {
          'property': 'Highlighted',
          'type': 'categorical',
          'stops': [
            [{'zoom':  4, 'value': true },  4.0],
            [{'zoom':  4, 'value': false},  1.5],
            [{'zoom': 20, 'value': true }, 12.0],
            [{'zoom': 20, 'value': false},  5.0],
          ],
        },
        'line-color': '#0077bb',
        'line-opacity': ['case', ['get', 'Highlighted'], 1.0, 0.8],
      }
    });

    if (mapType == 'airport-frequency-map') {
      var circleRadius = [
        'interpolate', ['linear'], ['zoom'],
        0, ['*', 2.0, ['sqrt', ['get', 'AirportVisitCount']]],
        10, ['*', 8.0, ['sqrt', ['get', 'AirportVisitCount']]]
      ];
      var circleOpacity = 0.5;
      var textVariableAnchor = ['center'];
    } else {
      var circleRadius = {
        'property': 'Highlighted',
        'type': 'categorical',
        'stops': [
          [{'zoom':  4, 'value': true }, 4],
          [{'zoom':  4, 'value': false}, 3],
          [{'zoom': 20, 'value': true }, 24],
          [{'zoom': 20, 'value': false}, 12],
        ],
      };
      var circleOpacity = 1.0;
      var textVariableAnchor = ['bottom','top','left','right'];
    }

    // Add airports.
    map.addLayer({
      'id': 'airports',
      'type': 'circle',
      'source': 'flights',
      'filter': ['==', '$type', 'Point'],
      'paint': {
        'circle-radius': circleRadius,
        'circle-color': '#000000',
        'circle-stroke-color': '#0077bb',
        'circle-stroke-width': 1,
        'circle-opacity': circleOpacity,
      }
    });

    var labelMinzoom = (mapType == 'single-flight-map') ? 0 : 3;

    // Add labels.
    map.addLayer({
      'id': 'airport-labels',
      'type': 'symbol',
      'source': 'flights',
      'filter': ['==', '$type', 'Point'],
      'minzoom': labelMinzoom,
      'layout': {
        'text-field': ['get', 'AirportIATA'],
        'text-variable-anchor': textVariableAnchor,
        'text-radial-offset': {
          'property': 'Highlighted',
          'type': 'categorical',
          'stops': [
            [{'zoom':  4, 'value': true }, 0.3],
            [{'zoom':  4, 'value': false}, 0.3],
            [{'zoom': 20, 'value': true }, 1.8],
            [{'zoom': 20, 'value': false}, 1.2],
          ],
        },
        'text-font': [
          'case',
          ['get', 'Highlighted'],
          ['literal', ['Source Sans Pro Semibold', 'DIN Pro Bold', 'Arial Unicode MS Bold']],
          ['literal', ['Source Sans Pro Regular', 'DIN Pro Regular', 'Arial Unicode MS Regular']],
        ],
        'text-size': ['case', ['get', 'Highlighted'], 15, 13],
        'symbol-sort-key': ['case', ['get', 'Highlighted'], 0, 1], // Lower value is higher priority
      },
      'paint': {
        'text-color': '#000000',
        'text-halo-color': '#ffffff',
        'text-halo-width': 1.5,
        'text-halo-blur': 2,
      },
    });

  });
}

function mapCenterZoom(geoJSONData) {
  const defaultValues = {center: [0, 20], zoom: 0.5, bounds: {w: -180.0, e: 180.0, n: 90.0, s: -90.0}};
  // Get MultiLineString features.
  let features = geoJSONData['features'];
  let routes = features.filter(r => r['geometry']['type'] == 'MultiLineString');
  if (routes.length == 0) {
      return defaultValues;
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

  // Calculate central longitude and bounds.
  let lonCenter = defaultValues['center'][0];
  if (lonStartValues.length > 0) {
    // Get center of of the widest of the lowest routeCount regions.
    lonCenter = lonStartValues[0][0] + (lonStartValues[0][1] / 2) + 180;
    while (lonCenter >= 180) {
      lonCenter = lonCenter - 360;
    }

    // Calculate bounds.
    if (lonStartValues[0][2] == 0) {
      boundE = lonStartValues[0][0];
      boundW = boundE + lonStartValues[0][1] - 360;
    } else {
      // Map goes around the world, so set east and west to center of lowest count region.
      boundE = lonCenter + 180;
      boundW = lonCenter - 180;
    }
    console.log(boundW, boundE);
  }

  return {center: [lonCenter, 20], zoom: 0.5};
};
