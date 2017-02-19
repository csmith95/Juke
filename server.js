var express = require('express');

var app = express();
var port = (process.env.PORT || 8000);
var mongoPort = (process.env.MONGOLAB_URI||'mongodb://localhost/juke');
var testData = require('./testingData');

var mongoose = require('mongoose');

require('./middleware.js')(app, express);

mongoose.connect(mongoPort);

// testData.addData();

app.listen(port);

console.log('server is running on port ' + port);
