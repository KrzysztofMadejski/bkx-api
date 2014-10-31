# Import
express = require('express')
bodyParser = require('body-parser');

app = express()

app.use(bodyParser.json())

app.use('/public_bikes', require('./public_bikes'));

module.exports = app;
