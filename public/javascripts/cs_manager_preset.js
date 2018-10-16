//need jquery && jquery-ui

$( function() {
	
	emotion_setting();
	menu_setting();
	
	fetch('api/json/tl')
		.then(function(response) {
			return response.json();
		}).then(function(myJson) {
			talk_tricks_setting(myJson);
		}).catch(function(error) {
			console.log(error);
		});
	
	set_manager_socket();
	
});

//設定 Socket 
function set_manager_socket(){
	
	Connection = {}
	
	Connection.init = function(){
		Connection.socket = io('http://localhost:1880/');
		Connection.customer_name = null;
		Connection.room_name = null;
		Connection.service_name = getUrlParameter("s")?b64DecodeUnicode(getUrlParameter("s")):UUID();
		
		Connection.end_point = "service" ;
		Connection.conn = false ;
		Connection.set_listener();
	}
	
	Connection.is_connect = function(){
		return Connection.socket.connected;
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
			reiceive_msg("與 '"+Connection.customer_name+"' 連線成功");
		});
		
		Connection.socket.on('reconnect', function () {
			Connection.conn = true;
			reiceive_msg("重新連接");
			reiceive_msg(Connection.room_name);
			Connection.socket.emit("enter", Connection.room_name);
		});
		
		Connection.socket.on('leave', function () {
			console.log("leave");
			console.log(Connection.next_customer_name);
			console.log(Connection.customer_name);
			if(Connection.next_customer_name){
				Connection.room_name = Connection.next_customer_name+"_"+Connection.service_name
				Connection.socket.emit("enter", Connection.room_name);
			}
			Connection.customer_name = Connection.next_customer_name;
			Connection.next_customer_name = null;
		});
		
	}
	
	Connection.send_msg = function(message){
		if(Connection.customer_name){
			Connection.socket.emit("message", {
				"type": Connection.end_point,
				"from": {
					"name": Connection.service_name,
					"avatar":"/images/avatar.png"
				},
				"to": {
					"name": Connection.customer_name,
					"avatar":"/images/avatar.png"
				},
				"time": Date.now(),
				"message": {
					"type": "text",
					"text": message
				},
				//"command": []
			});
		}else{
			alert('無對象');
		}
	}
	
	Connection.change_customer = function(customer_id){
		console.log(customer_id);
		Connection.next_customer_name = customer_id;
		Connection.socket.emit('leave',Connection.room_name);
	}
	
	Connection.get_history_unread = function(){
		
	}
	
	Connection.get_history_last = function(){
		
	}
	
	Connection.get_history_unread = function(){
		
	}
	
	Connection.init();
}

//金牌話術
function talk_tricks_setting(data){
	
	let talk_tricks_str = data.map(function(item){
		return `<a class='talk_trick'>${item}</a>`;
	}).join("");
	
	$("#talk_tricks_container").html(talk_tricks_str);
	
	$("#talk_tricks_container").delegate( ".talk_trick", "click", function() {
		$(".input").val($(this).text());
	});
}

//功能選單
function menu_setting(){
	
	$(".btn-add").click(function(){
		$(".select-menu").toggle();
	});
	
	$(".select-menu a").click(function(){
		let func_name = $(this).text().trim();
		if(func_name=="相機"){
			
			if (window.stream) {
				if (window.stream) {
					window.stream.getTracks().forEach(function(track) {
					  track.stop();
					});
				}
				window.stream = null;
				$("#video_container").html('<video autoplay=""> </video>');
				
			}else{
				navigator.mediaDevices.getUserMedia({ video: true}).
					then((stream) => { 
						window.stream = stream;
						document.querySelector('video').srcObject = stream;
					});	
			}
			
			$("#video_container").toggle();
			$("#video_container").position({
				my: "left+10 top+10",
				at: "left top",
				of: "#console"
			});
			
		}else if(func_name=="金牌話術"){
			$("#talk_tricks_container").toggleClass("enable"); 
		}else{
			alert(func_name);
		}
		
		$(".select-menu").toggle();
	});
}