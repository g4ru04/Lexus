//need jquery && jquery-ui

$( function() {
	emotion_setting();
	
	set_customer_socket();
	
	$(".header_content .txt").html(Connection.service_name);
});

//設定 Socket 
function set_customer_socket(){
	
	Connection = {}
	
	Connection.init = function(){
		Connection.socket = io('http://localhost:1880/');
		Connection.client_name  = getUrlParameter("c")?b64DecodeUnicode(getUrlParameter("c")):UUID();
		Connection.service_name = getUrlParameter("s")?b64DecodeUnicode(getUrlParameter("s")):UUID();
		Connection.room_name = Connection.client_name+"_"+Connection.service_name;
		Connection.end_point = "client" ;
		Connection.conn = false ;
		Connection.set_listener();
		Connection.socket.emit("enter", Connection.room_name);
	}
	
	Connection.is_connect = function(){
		return Connection.socket.connected;
	}
	
	Connection.set_listener = function(){
		
		Connection.socket.on('message', function (data) {
			console.log(data);
			reiceive_msg(data);
		});
		
		Connection.socket.on('disconnect', function () {
			reiceive_msg('已斷線');
		});
		
		Connection.socket.on('enter', function () {
			Connection.conn = true;
			reiceive_msg("與 '"+Connection.service_name+"' 連線成功");
		});
		
		Connection.socket.on('reconnect', function () {
			Connection.conn = true;
			reiceive_msg("重新連接");
			Connection.socket.emit("enter", Connection.room_name);
		});
		
	}
	
	Connection.send_text = function(message){
		Connection.socket.emit("message", {
			"type": Connection.end_point,
			"from": {
				"name": Connection.client_name,
				"avatar":"/images/avatar.png"
			},
			"to": {
				"name": Connection.service_name,
				"avatar":"/images/avatar.png"
			},
			"time": Date.now(),
			"message": {
				"type": "text",
				"text": message
			},
			//"command": []
		});
	}
	
	Connection.send_image = function(url){
		Connection.socket.emit("message", {
			"type": Connection.end_point,
			"from": {
				"name": Connection.client_name,
				"avatar":"/images/avatar.png"
			},
			"to": {
				"name": Connection.service_name,
				"avatar":"/images/avatar.png"
			},
			"time": Date.now(),
			"message": {
				"type": "image",
				"url": url
			},
			//"command": []
		});
	}
	
	Connection.get_history = function(){
		
	}
	
	Connection.get_history_last = function(){
		
	}
	
	Connection.init();

}