module.exports = {
	"develop": true,
	"socket_server": {
		"ip": "http://localhost:8082/",
	},
	"hoital_api":{
		"develop": "https://htsr.hotaimotor.com.tw/LINEAPI_TEST/Service.asmx/",
		//"develop": "https://nodered-api-lexus-test01.mybluemix.net/ht_api/",
		"product": "https://htsr.hotaimotor.com.tw/LINEAPI/Service.asmx/"
	},
	line: {
		"sendmessage": "https://htsr.hotaimotor.com.tw/LINENOTIFYAPI_TEST/LineNotify/SendMessage/"
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