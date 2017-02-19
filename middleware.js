var morgan = require('morgan');
var bodyParser = require('body-parser');
var groupController = require('./database/groupController.js');
var userController = require('./database/userController.js');
// var SQLController = require('./db/SQL/SQLController.js');

module.exports = function(app, express){
	//This section handles the basic middleware
	app.use(morgan('dev')); // Console logs the incoming requests 
	app.use(bodyParser.json()); // Allows the body to be accessed
	app.use(bodyParser.urlencoded({extended: true})); //Allows the URL to be accessed


	//Serves the public directory to the user
	app.use(express.static(__dirname + '/../public'));


	// //Database Requests
	app.post('/updateLocation', userController.updateLocation);

	app.post('/createGroup', groupController.createGroup);
	app.post('/addMember', groupController.addMember);
	app.post('/vote', groupController.vote);
	app.get('/findNearbyGroups', groupController.findNearbyGroups);

};