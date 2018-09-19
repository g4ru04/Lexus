(function() {
	function common() {}
	common.prototype.getSl = function(req, res) {
		var data = require('./specialist.json', 'utf-8');
		return res.send(data);
	}
	common.prototype.getCl = function(req, res) {
		var data = require('./customer.json', 'utf-8');
		return res.send(data);
	}
	module.exports = new common();
}());