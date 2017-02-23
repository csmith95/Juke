var Group = require('./groupModel.js');


var objToArray = function(object){
	var array = [];
	for(var key in object){
		array.push(object[key]);
	}
	return array;

};

module.exports = {
	createGroup: function(req, res, next){
		Group.findOne({"groupName":req.body.groupName}, function(err, group) {
			if(group) {
				res.send(300, "Group already exists")
			} else {
				var group = new Group;
				group.groupName = req.body.groupName; 
				group.owner =  req.body.owner;
				group.password =  req.body.password;
				group.members =  objToArray(req.body.members);
				group.latLocation =  req.body.latitude;
				group.lngLocation =  req.body.longitude;

				group.save(function(err, resp){
					if(err){
						res.send(300, "Error creating group")
					}

					res.send(200, resp);
				});
			}
		})
	},

	//Finds group by groupname


	findNearbyGroups : function(req, res, next){
		//This part performs a url extraction to find out which group the owner is trying to access. It will later deal with 
		//possible issues of there being additial arguments such as person in group selection. 
		var locLat = req.url.split('/')[2].substring(0,req.url.split('/')[2].length - 2);
		var locLng = req.url.split('/')[3].substring(0,req.url.split('/')[3].length - 2);

		Group.find({"lngLocation":{"$regex": locLng, "$options": "i"}, "latLocation":{"$regex": locLat, "$options": "i"}}, function(err, group){
			if(err){
				console.log(err);
			}
			res.send(200, group);
		});
	},



	addMember:function(req, res, next){
		Group.findOne({"groupName":req.body.groupName}, function(err, group) {
			if(group){
				group.members.push(req.body.username);
				group.members = Array.from(new Set(group.members));
				group.save(function(err, data){
					res.send(200, data);
				});
			} else {
				res.send(200, 'GROUP NOT FOUND');
			}

		});
	},
	addSong:function(req, res, next){
		Group.findOne({"groupName":req.body.groupName}, function(err, group) {
			if(group){
				group.songs.push(req.body.songname);
				group.voteIndex.push(0)
				group.save(function(err, data){
					res.send(200, data);
				});
			} else {
				res.send(200, 'GROUP NOT FOUND');
			}

		});
	},

	popSong:function(req, res, next){
		Group.findOneAndUpdate({"groupName":req.body.groupName}, { "$pop": { "songs": -1 , "voteIndex": -1 ,} },{ "returnOriginal": false }, function(err, group) {
			if(group){
				res.send(200, group)
			} else {
				res.send(200, 'GROUP NOT FOUND');
			}

		});
	},


	vote : function(req,res, next){
		var groupname = req.body.groupName
		var songname = req.body.songname

		Group.findOne({groupName:req.body.groupName}, function(err, group) {
			if(group){
				for(var i = 0 ; i < group.songs.length ; i++) {
					if(group.songs[i] == songname){
						group.voteIndex[i] = 1 + group.voteIndex[i]
					}
				}
				console.log("HELLO")
				console.log(group)
				group.markModified('voteIndex');
				group.save(function(err, data) {
					console.log(data)
					res.send(200, group);
				});

			} else {
				res.send(200, 'GROUP NOT FOUND')
			}
		});
		
	}
};
