(function() {

	// 20181102 - Michael
	
	class ht_api{
		
		constructor() {
			this.callApi = this.callApi.bind(this);
		}

		callApi(body) {
			return new Promise(async function(resolve, reject){
				var detail = body.detail || false;
				const settings = require('../configs.js');
				const table = [
					/* 01 */ "LINE001_Q01",
					/* 02 */ "LINE006_Q00",
					/* 03 */ "LINE006_Q01",
					/* 04 */ "LINELCS01_Q01",
					/* 05 */ "LINELCS02_D01",
					/* 06 */ "LINELCS02_I01",
					/* 07 */ "LINELCS02_Q01",
					/* 08 */ "LINELCS02_Q02",
					/* 09 */ "LINELCS02_Q03",
					/* 10 */ "LINELCS03_Q01",
					/* 11 */ "LINELCS03_Q02",
					/* 12 */ "SendMessage",
					/* 13 */ "USER_LOGIN"]

				try{
					
					if(!body.api) throw Error("body.api is necessary");
					if(!body.data) throw Error("body.data is necessary");

					if(!table.includes(body.api)) throw Error("no corresponding api");
					var targetApi = body.api, 
						environment = settings.develop ? "develop" : "product";

					var result = await callApi({
						url: settings.hoital_api[environment] + targetApi,
						body: {
							"jsonstr": JSON.stringify(body.data)
						}
					}, detail);
					resolve(result);

				}catch(e){
					resolve(returnMessage(false, 'Parse request fail' + detail ? (': ' + e.toString()) : ''));
				}
			})
		}
	}
	
	module.exports = new ht_api();

	/// private functions

	async function callApi(params, detail){
		return new Promise(async function(resolve, reject){
			try{
				var request = require("request");
				var querystring = require("querystring");
	
				request({
					headers: {
						'Content-Type': 'application/x-www-form-urlencoded'
					},
					url: params.url,
					body: querystring.stringify(params.body),
					method: 'POST'
					}, function (err, res, body) {
						if(err)  resolve(returnMessage(false, 'Api server return error' + detail ? (': ' + err.tostring()) : ''));
	
						var result = returnMessage(true, JSON.parse(body.replace(/[\r\n\t]/g,"")));
						resolve(result);
					});
				
			}catch(e){
				console.log('1')
				resolve(returnMessage(false, 'Call Api fail' + detail ? (': ' + e.toString()) : ''));
			}
		})
	}

	function returnMessage(isSuccess, msg){
		return {
			isSuccess: isSuccess,
			result: msg
		}
	}
}());

