express = require('express');
router = express.Router();
mysql = require('mysql');

config = require './config/cartodb'
v = require './validators/public_bikes'


router.get '/', (req, res) ->
  res.status 200
    .json { message: "My first route"}


router.post '/', (req, res) ->

  # Validate input
  vresp = v.validate req.body, v._network
  if vresp.errors.length
    res.status 422
    .json {
        errno: 'INPUT_VALIDATION_FAILED',
        params: vresp.errors
      }
    return

  # Authorize
  alias = req.body.alias

  unless req.query.api_key
    res.status 401
      .json "Please specify api_key"
    return

  # TODO authorize: does api_key can write to alias

  # Build INSERT
  sql = "INSERT INTO public_bikes (alias, the_geom, src_id, station_id, station_name, total_docks, city_name) VALUES "
  #TODO insert nulls correctly (see below "use params to sanitize")
  sql += for f in req.body.stations.features
    pt = f.geometry.coordinates
    f = f.properties
    "(#{mysql.escape alias}, ST_GeomFromText('POINT(#{mysql.escape pt[0]} #{mysql.escape pt[1]})', 4326), #{mysql.escape ""+f.uniqueId},
    #{mysql.escape f.stationId}, #{mysql.escape f.stationName}, #{mysql.escape f.totalDocks}, #{mysql.escape f.cityName})"


  # Send data to server
  CartoDB = require('cartodb');
  client = new CartoDB config

  client.on 'connect', ->
    # TODO use params to sanitize
    client.query sql, {}, (err, data) ->
      if err
        ret = JSON.parse err
        ret.sql = sql
        res.status 422
        .json ret

      else
        res.status 200
        .json data

  client.connect()

module.exports = router
