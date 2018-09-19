(function() {
	
	class Common{
		constructor() {
			this.getSl = this.getSl.bind(this);
			this.getCl = this.getCl.bind(this);
		}
		getSl(req, res) {
			var data = require('./specialist.json', 'utf-8');
			return res.send(data);
		}
		getCl(req, res) {
			var data = require('./customer.json', 'utf-8');
			return res.send(data);
		}
	}
	
	module.exports = new Common();
	
}());

