var groupController = require('./database/groupController.js');
var userController = require('./database/userController.js');

module.exports = {
	addData:function() {
		var reqUser1 = {
			"body":{
				username: "Linus",
				groups: [],
				latLocation: "37.754023",
				lngLocation: "-122.431641"

			},
			"url" : "www/w/37.754023/ -122.431641"
		}
		console.log("HELLO")

		var group1 = {
			"body":{

			groupName: "Linu Group",
			owner: "Linus",
			members: [],
			latLocation: "37.754023",
			lngLocation: "-122.431641",
			password: "",
			songs:[],
			voteIndex:{}
		}
		}

		res = {
			send: function(responseCode, message) {
				console.log(responseCode)
				console.log(message)
			}
		}

		// userController.updateLocation(reqUser1, res, {})
		// groupController.createGroup(group1, res, {})

		var groupPair = {"body":{groupName:"Linu Group", username:"Linus"}}
		var groupPair1 = {"body":{groupName:"Linu Group", username:"Linus1"}}
		var groupPair2 = {"body":{groupName:"Linu Group", username:"Linus2"}}
		var groupPair3 = {"body":{groupName:"Linu Group", username:"Linus3"}}

		// groupController.addMember(groupPair, res, {})
		// groupController.addMember(groupPair1, res, {})
		// groupController.addMember(groupPair2, res, {})
		// groupController.addMember(groupPair3, res, {})

		var song1 = {"body":{songname:"Eye of the Tiger",groupName:"Linu Group"}}

		// groupController.addSong(song1, res, {} )

		var vote1 = {"body":{songname:"Eye of the Tiger", groupName:"Linu Group"}}
		groupController.vote(vote1, res, {})

		groupController.findNearbyGroups(reqUser1, res, {})
	}
}