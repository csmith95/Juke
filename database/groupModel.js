var mongoose = require('mongoose');

var Group = new mongoose.Schema({
	groupName: String,
	owner: String,
	password: String,
	members: [String],
	songs:[String],
	voteIndex:[Number],
	latLocation: String,
	lngLocation: String


});

module.exports = mongoose.model('Groups', Group);