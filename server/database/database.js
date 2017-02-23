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
		console.log(req.body.members);
		var group = new Group ({
			groupName: req.body.group,
			owner: req.body.owner,
			password: req.body.password,
			members: objToArray(req.body.members)
		});

		console.log(group);
		group.save(function(err, resp){
			if(err){
				console.log(err);
			}

			res.send(200, resp);
		});
	},

	//Finds group by groupname
	findGroup : function(req, res, next){
		//This part performs a url extraction to find out which group the owner is trying to access. It will later deal with 
		//possible issues of there being additial arguments such as person in group selection. 
		var owner = req.url.split('/')[3];
		console.log(owner);
		Group.find({'owner': owner}, function(err, group){
			if(err){
				console.log(err);
			}
			res.send(200, group);
		});
	},


	//This is an innefficient process allowing for finding which groups a user is in and returning a list of them
	//It will later be replaced by a many to many relationship table
	findGroups : function(req, res, next){
		var username = req.url.split('/')[2];
		Group.find({}, {'password': 0},function(err, response){
			var result = [];
			for(var i = 0 ; i < response.length; i ++){
				if(response[i].members.indexOf(username)!==-1){
					result.push(response[i]);
				}
			}
			res.send(200, result);
		});
	},	

	addMember:function(req, res, next){
		Group.findOne({groupName: req.body.group}, function(err, group){
			if(group){
				group.members.push(req.body.username);
				group.save(function(err, data){
					res.send(200, data);
				});
			} else {
				res.send(200, 'GROUP NOT FOUND');
			}

		});
	},


	allGroups : function(req,res, next){

		Group.find({}, 'groupName owner members' , function(err, groups){
			if(groups){
				res.send(200, groups);
			} else {
				res.send(200, 'GROUP NOT FOUND')
			}
		});
		
	}
};