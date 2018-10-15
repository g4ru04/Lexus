//need jquery && jquery-ui

$( function() {
	emotion_setting();
	
	set_customer_socket();
	//set_client_socket('hello');
	$(".header_content .txt").html(Connection.service_name);
});

//click or event 使用
function reiceive_msg(message){
	
	if(message.message!=null){
		$("#console").append(message.from + ": " + message.message.text + "<br>");
	}else{
		$("#console").append(
			JSON.stringify(message,null,"    ")
				.replace(/    /g,"&nbsp;&nbsp;&nbsp;")
				.replace(/\n/g,"<br>")
			+"<br>"
		);
	}
	
}

//click or event 使用
function send_text_msg(){
	
	if(Connection){
		Connection.send_msg($("input.input.msg").val());
		$("input.input.msg").val('');
	}
	
}

//設定 Socket 
function set_customer_socket(){
	
	Connection = {}
	
	Connection.init = function(){
		Connection.socket = io('http://localhost:1880/');
		Connection.client_name  = getUrlParameter("c")?b64DecodeUnicode(getUrlParameter("c")):UUID();
		Connection.service_name = getUrlParameter("s")?b64DecodeUnicode(getUrlParameter("s")):UUID();
		
		Connection.end_point = "client" ;
		Connection.conn = false ;
		Connection.set_listener();
		Connection.socket.emit("enter", Connection.client_name+"_"+Connection.service_name);
	}
	
	Connection.set_listener = function(){
		Connection.socket.on('message', function (data) {
			reiceive_msg(data);
		});
		Connection.socket.on('disconnect', function () {
			reiceive_msg('已斷線');
		});
		Connection.socket.on('enter', function () {
			Connection.conn = true;
			reiceive_msg("與 '"+Connection.service_name+"' 連線成功");
		});
	}
	
	Connection.send_msg = function(message){
		Connection.socket.emit("message", {
			"from": Connection.client_name,
			"to": Connection.service_name,
			"time": Date.now(),
			"message": {
				"type": "text",
				"text": message
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