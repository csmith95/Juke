var express = require('express');
var app = express();
var port =  8000;
var testData = require('./testingData');

var mongoose = require('mongoose');

require('./middleware.js')(app, express);

mongoose.connect('mongodb://localhost/juke');

testData.addData();

app.listen(port);

console.log('server is running on port ' + port);
