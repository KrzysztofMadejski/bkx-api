Validator = require('jsonschema').Validator;
v = new Validator();

# TODO schemas in separate files

v._network = {
  id: '/Network', # TODO ids AS URIsm ie. http://jsonschema.bikestorming.org/public_bikes/network
  type: 'object',
  properties: {
    name: {
      type: 'string'},
    alias: {
      type: 'string'},
    countryCode: {
      type: 'string'},
    cityName: {
      type: 'string'},
    cityLatitude: { # todo geo reference
      type: 'number'},
    cityLongitude: {
      type: 'number'},

    stations: {
      "$ref": "/StationGeoJson"
    }

    #Optional fields:
      #icon
      #cityBoundaries: geojson
      #hotline
    # feescheme

  },
  required: ['name', 'alias', 'countryCode', 'cityName', 'cityLatitude', 'cityLongitude'],
  "$schema": "http://json-schema.org/draft-04/schema#",
}

v._station_geojson = {
  id: '/StationGeoJson',
  type: 'object',
  required: ['type', 'features'],
  definitions: {
    "stationProperties": {
      type: 'object',
      properties: {
        uniqueId: {
          type: 'string'},
        stationId: {
          type: 'string'},
        stationName: {
          type: 'string'},
        totalDocks: {
          type: ['integer', 'null']}, #TODO do we allow nulls like that in optional elements?
        canParkIfNoDocksAvailable: {
          type: 'boolean'},

      },
      required: ['uniqueId']
    }
  }
  properties: {
    'type': {
      type: 'string',
      pattern: 'FeatureCollection'},
    'features': {
      type: 'array',
      items: {
        type: 'object',
        required: ['type', 'geometry', 'properties'],
        properties: {
          'type': {
            type: 'string',
            pattern: 'Feature'},
          'geometry': {
            type: 'object', # ewentualnie { "$ref": "#/definitions/diskDevice" },
            properties: {
              type: {
                type: 'string',
                pattern: 'Point'},
              coordinates: {
                type: 'array',
                maxItems: 2,
                minItems: 1,
                items: {
                  type: 'number'
                }
              }
            }
          },
          'properties': {
            '$ref': '#/definitions/stationProperties'
          }
        }
      }
    }
  },
  "$schema": "http://json-schema.org/draft-04/schema#",
}

v.addSchema(v._network, '/Network')
v.addSchema(v._station_geojson, '/StationGeoJson')

module.exports = v