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

	//Requires username and latLocation lngLocation
	app.post('/updateLocation', userController.updateLocation);

	//Requires username, latLocation, lngLocation, 
	app.post('/createGroup', groupController.createGroup);

	//Adds a member to a group, Requires username, groupname
	app.post('/addMember', groupController.addMember);

	//Doesn't work yet
	app.post('/vote', groupController.vote);

	//Requires a groupname, songname, and username where user must be in the group
	app.post('/addSong', groupController.addSong);

	//Requires only a group name
	app.post('/popSong', groupController.popSong);

	//Requies a latLocationa and lngLocation
	app.get('/findNearbyGroups', groupController.findNearbyGroups);

};