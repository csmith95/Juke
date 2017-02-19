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


	//Requires username and latLocation lngLocation
	//uri: wwww.yourwebsite.com/updateLocation/
	//req.body = {username:"Linus", latLocation:1412.31,lngLocation:13134.31}
	app.post('/updateLocation', userController.updateLocation);

	//Requires username, latLocation, lngLocation, groupName,  
	//uri: wwww.yourwebsite.com/createGroup/
	//req.body = {username:"Linus",groupName:"My group", latLocation:1412.31,lngLocation:13134.31}
	app.post('/createGroup', groupController.createGroup);

	//Adds a member to a group, Requires username, groupname
	app.post('/addMember', groupController.addMember);

	//Doesn't work yet
	app.post('/vote', groupController.vote);

	//Requires a groupname, songname, and username where user must be in the group
	app.post('/addSong', groupController.addSong);

	//Requires only a group name
	//
	app.post('/popSong', groupController.popSong);

	//Requies a request to url wwww.yourwebsite.com/findNearbyGroups/latLocation/lngLocation
	app.get('/findNearbyGroups', groupController.findNearbyGroups);

};