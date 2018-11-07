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
		Connection.client_id  = client_id_b64?b64DecodeUnicode(client_id_b64):UUID();
		Connection.service_id = service_id_b64?b64DecodeUnicode(service_id_b64):UUID();
		Connection.client_info = {
			"id":"",
			"name":"",
			"avator":"/images/avator.png",
			"PHONE":""
		};
		Connection.service_info = {
			"id":"",
			"name":"",
			"avator":"/images/avator.png",
			"PHONE":""
		};;
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
		
		Connection.socket.on('enter', function (data) {
			console.log(data);
			try {
				let conversation_data = data[0][0];
				Connection.client_info = JSON.parse(conversation_data.customer_data);
				Connection.service_info = JSON.parse(conversation_data.manager_data);
			}catch(err) {
				console.log(err);
			}
			
			Connection.conn = true;
			my_console("【"+Connection.client_id+"-"+Connection.service_id+"】 連線成功");
			Connection.socket.emit("register client",{});
			if(Connection.talks_history_cursor==0){
				Connection.socket.emit("get history",{});
			}
		});
		
		Connection.socket.on('reconnect', function () {
			Connection.conn = true;
			my_console("重新連接");
			//$("#console").html('<div class="loading_div"><img src="/images/loading.gif" /></div>');
			Connection.socket.emit("enter", {
				type : Connection.end_point,
				client_id : Connection.client_id,
				service_id : Connection.service_id
			});
		});
	}
	
	Connection.reiceive_msg = function (message){
		$("#console").append(produce_dialog_element(message));
		$("#console").scrollTop($('#console')[0].scrollHeight);
	}
	
	Connection.init();

}