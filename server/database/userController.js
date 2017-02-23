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
				var newUser = new User;
				newUser.username = username;
				newUser.lngLocation =  lngLocation;
				newUser.latLocation = latLocation;
				newUser.groups =  [];
				newUser.save(function(err, result) {
					if(err){
						res.send(300, "Failed to find user ");							
					} else {
						res.send(200, result);	
					}
				});
			}
		})
	}


};