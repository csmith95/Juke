var express = require('express');

var app = express();
var port = (process.env.PORT || 8000);
var mongoPort = ("mongodb://<dbuser>:<dbpassword>@ds157509.mlab.com:57509/heroku_n3p6t5w7"||'mongodb://localhost/juke');
console.log(process.env.MONGOLAB_URI)
var testData = require('./testingData');

var mongoose = require('mongoose');

require('./middleware.js')(app, express);

mongoose.connect(mongoPort);

// testData.addData();

app.listen(port);

console.log('server is running on port ' + port);
