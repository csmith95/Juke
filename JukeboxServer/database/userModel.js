var mongoose = require('mongoose');

var Users = new mongoose.Schema({
	username: String,
	groups: [String],
	latLocation: String,
	lngLocation: String
});

module.exports = mongoose.model('Users', Users);