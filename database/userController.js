var User = require('./userModel.js');

module.exports  = {

	updateLocation: function(req, res, next) {
		var username = req.body.username;
		var latLocation = req.body.latitude;
		var lngLocation = req.body.longitude;
		User.findOne({'username': username}, function(err, result) {
			if(result){
				result.latLocation = latLocation;
				result.lngLocation = lngLocation
				res.send(200, "Location Updated");	
			} else {
				var newUser = new User({
					username:username,
					lngLocation: lngLocation,
					latLocation:latLocation,
					groups: []
				});
				newUser.save();
				res.send(200, newUser);	
			}
		})
	}


};