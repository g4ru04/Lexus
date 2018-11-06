module.exports = {
	"develop": true,
	"socket_server": {
		//"ip": "http://localhost:80/",
		"ip": "https://nodered-api-lexus-test.mybluemix.net/"
		
	},
	"hoital_api":{
		//"develop": "https://htsr.hotaimotor.com.tw/LINEAPI_TEST/Service.asmx/",
		"develop": "https://nodered-api-lexus-test.mybluemix.net/ht_api/",
		"product": "https://htsr.hotaimotor.com.tw/LINEAPI/Service.asmx/"
	}
	/*,
	"mysql_db":{
		"host":"127.0.0.1",
		"port":"3306",
		"user":"root",
		"password":""
	},
	"mongo_db":{
		"host":"127.0.0.1",
		"port":"27017",
		"username":"",
		"password":""
	},
	"mqtt":{
		"server":"192.168.112.166",
		"port":"1883",
		"username":"mqtt",
		"password":""
	}
	*/
	
}