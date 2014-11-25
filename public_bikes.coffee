express = require('express');
router = express.Router();
mysql = require('mysql');

config = require './config/cartodb'
v = require './validators/public_bikes'

queue = (err, funcs...) ->
  _call = (idx) ->
    if funcs.length <= idx
      return true # All succeeded

    # call next function
    funcs[idx] -> # error
      err(idx, funcs[idx])
      return false

    , -> # success
      _call idx + 1

  _call 0

escapess = (value) ->
  if not value?
    return 'NULL'
  else if typeof value is 'string'
    "'" + value.replace(/'/g, "''") + "'"
  else
    value

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

  # Send data to server
  CartoDB = require('cartodb');
  client = new CartoDB config

  sql_error = (err, sql) ->
    unless res.headersSent # error occured while updating other row, pass on that one
      ret = JSON.parse err
      ret.sql = sql
      res.status 422
      .json ret

  mark_all_deleted = (error, success) ->
    sqlu = "UPDATE public_bikes SET deleted=TRUE WHERE alias=#{escapess alias}"
    client.query sqlu, {}, (err,data) ->
      if err
        sql_error err, sqlu
        error()
      else
        success()

  existing_ids = {}
  select_all = (error, success) ->
    sqls = "SELECT src_id FROM public_bikes WHERE  alias=#{escapess alias}"
    client.query sqls, {}, (err,data) ->
      if err
        sql_error err, sqls
        error()

      else
        # TODO will fail if a new id is twice in input
        for r in data.rows
          existing_ids[r.src_id] = true
        success()

  updated = 0
  inserted = 0
  insert_new = (error, success) ->
    queued = {}
    check_if_done = ->
      for st of queued
        if queued[st] == 'processing'
          return false

      success()
      return true

    for f in req.body.stations.features
      queued[f.properties.uniqueId] = 'processing'

    for f in req.body.stations.features
      do (f) ->
        pt = f.geometry.coordinates
        f = f.properties

        if existing_ids[f.uniqueId]
          sql = "UPDATE public_bikes SET deleted = FALSE WHERE src_id = #{escapess f.uniqueId}"
          client.query sql, {}, (err,data) ->
            if err
              sql_error err, sql
              error()
            else
              updated++
              queued[f.uniqueId] = 'updated'
              check_if_done()

        else
          sql = "INSERT INTO public_bikes (alias, the_geom, src_id, station_id, station_name, total_docks, city_name, deleted) VALUES "

          sql += "(#{escapess alias}, ST_GeomFromText('POINT(#{escapess pt[0]} #{escapess pt[1]})', 4326), #{escapess ""+f.uniqueId},
              #{escapess f.stationId}, #{escapess f.stationName}, #{escapess f.totalDocks}, #{escapess f.cityName}, FALSE)"

          client.query sql, {}, (err,data) ->
            if err
              sql_error err, sql
              error()
            else
              inserted++
              queued[f.uniqueId] = 'inserted'
              check_if_done()


  client.on 'connect', ->
    queue ((err_idx)-> console.log 'function failed: ' + err_idx), select_all, mark_all_deleted, insert_new, ->
      resp = {
        network: req.body.alias,
        received: req.body.stations.features.length,
        inserted: inserted,
        updated: updated,
        deleted: Object.keys(existing_ids).length - updated # TODO deleted = those that weren't delted before (existing is all)
      }
      console.log resp
      res.status 200
      .json resp

  client.connect()

module.exports = router
