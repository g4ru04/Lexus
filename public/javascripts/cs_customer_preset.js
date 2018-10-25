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
		Connection.socket = io(socket_server_ip);
		Connection.client_id  = getUrlParameter("c")?b64DecodeUnicode(getUrlParameter("c")):UUID();
		Connection.service_id = getUrlParameter("s")?b64DecodeUnicode(getUrlParameter("s")):UUID();
		Connection.end_point = "client" ;
		Connection.conn = false ;
		Connection.set_listener();
		Connection.talks = [];
		Connection.talks_history_cursor = 0;
		Connection.socket.emit("enter", {
			type : Connection.end_point,
			client_id : Connection.client_id,
			service_id : Connection.service_id
		});
		
	}
	
	Connection.is_connect = function(){
		return Connection.socket.connected;
	}
	
	Connection.set_listener = function(){
		
		Connection.socket.on('message', function (data) {
			console.log(data);
			Connection.talks_history_cursor += 1;
			Connection.talks.push(data);
			reiceive_msg(data);
		});
		
		Connection.socket.on('disconnect', function () {
			reiceive_msg('已斷線');
		});
		
		Connection.socket.on('enter', function () {
			Connection.conn = true;
			reiceive_msg("與 '"+Connection.service_id+"' 連線成功");
			Connection.socket.emit("register client",{});
			Connection.socket.emit("get history",{});
		});
		
		Connection.socket.on('reconnect', function () {
			Connection.conn = true;
			reiceive_msg("重新連接");
			Connection.socket.emit("enter", {
				type : Connection.end_point,
				client_id : Connection.client_id,
				service_id : Connection.service_id
			});
		});
		
		Connection.socket.on('get history', function (data) {
			console.log(data);
			Connection.talks_history_cursor += data.data.length;
			Connection.talks = Connection.talks.concat(data.data);
			//此為補上歷史資料
			data.data.sort(function(a,b){
				return b.time - a.time;
			});
			smoothly_set_history(JSON.parse(JSON.stringify(data.data)));

		});
	}
	
	Connection.send_text = function(message){
		Connection.socket.emit("message", {
			"type": Connection.end_point,
			"from": {
				"id": Connection.client_id,
				"avatar":"/images/avatar.png"
			},
			"to": {
				"id": Connection.service_id,
				"avatar":"/images/avatar.png"
			},
			"time": Date.now(),
			"message": {
				"type": "text",
				"text": message
			}
		});
	}
	
	Connection.send_image = function(url){
		Connection.socket.emit("message", {
			"type": Connection.end_point,
			"from": {
				"id": Connection.client_id,
				"avatar":"/images/avatar.png"
			},
			"to": {
				"id": Connection.service_id,
				"avatar":"/images/avatar.png"
			},
			"time": Date.now(),
			"message": {
				"type": "image",
				"url": url
			}
		});
	}
	
	Connection.get_history = function(num){
		num = num?num:10;
		if(!Connection.getting_history){
			Connection.getting_history = true;
			$("#console .loading_div").addClass("active");
			Connection.socket.emit("get history",{
				"skip": Connection.talks_history_cursor,
				"limit":num
			});
		}
	}
	
	Connection.init();

}