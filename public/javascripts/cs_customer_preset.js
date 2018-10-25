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
		
		Connection.end_point = "client" ;
		Connection.client_id  = getUrlParameter("c")?b64DecodeUnicode(getUrlParameter("c")):UUID();
		Connection.service_id = getUrlParameter("s")?b64DecodeUnicode(getUrlParameter("s")):UUID();
		Connection.conn = false ;
		Connection.talks = [];
		Connection.talks_history_cursor = 0;
		
		Connection.set_listener();
		common_conn_setting(Connection);
		
		Connection.socket.emit("enter", {
			type : Connection.end_point,
			client_id : Connection.client_id,
			service_id : Connection.service_id
		});
		
	}
	
	Connection.set_listener = function(){
		
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
	}
	
	Connection.init();

}