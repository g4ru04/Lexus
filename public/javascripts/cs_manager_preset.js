//need jquery && jquery-ui

$( function() {
	
	emotion_setting();
	menu_setting();
	
	$.getJSON( "/api/json/tl", function( data ) {
		talk_tricks_setting(data);
	});
	
	set_manager_socket();
	
});

//設定 Socket 
function set_manager_socket(){
	
	Connection = {}
	
	Connection.init = function(){
		Connection.socket = io(socket_server_ip);
		Connection.client_id = null;
		//Connection.room_name = null;
		Connection.service_id = getUrlParameter("s")?b64DecodeUnicode(getUrlParameter("s")):UUID();
		
		Connection.end_point = "service" ;
		Connection.conn = false ;
		Connection.set_listener();
		Connection.socket.emit("register service",{
			type : Connection.end_point,
			service_id : Connection.service_id,
		});
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
		
		Connection.socket.on('enter', function (data) {
			Connection.conn = true;
			reiceive_msg("與 '"+Connection.client_id+"' 連線成功");
		});
		
		Connection.socket.on('reconnect', function () {
			Connection.conn = true;
			reiceive_msg("重新連接");
			//reiceive_msg(Connection.room_name);
			Connection.socket.emit("enter",{
				type : Connection.end_point,
				client_id : Connection.client_id,
				service_id : Connection.service_id,
			});
		});
		
		Connection.socket.on('leave', function () {
			console.log("leave: "+Connection.client_id);
			console.log("join: "+Connection.next_client_id);
			if(Connection.next_client_id){
				//Connection.room_name = Connection.next_client_id+"_"+Connection.service_id;
				Connection.socket.emit("enter", {
					type : Connection.end_point,
					client_id : Connection.next_client_id,
					service_id : Connection.service_id
				});
			}
			Connection.client_id = Connection.next_client_id;
			Connection.next_client_id = null;
		});
		
		Connection.socket.on('update conversatoin list', function (data) {
			setTimeout(function(){
				update_conversatoin_list(data[0]);
			},100);
			
		});
		
	}
	
	Connection.send_text = function(message){
		if(Connection.client_id){
			Connection.socket.emit("message", {
				"type": Connection.end_point,
				"from": {
					"id": Connection.service_id,
					"avatar":"/images/avatar.png"
				},
				"to": {
					"id": Connection.client_id,
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
	
	Connection.change_customer = function(client_id){
		console.log(client_id);
		Connection.next_client_id = client_id;
		Connection.socket.emit('leave',{
			type : Connection.end_point,
			client_id : Connection.client_id,
			service_id : Connection.service_id
		});
	}
	
	Connection.get_history_unread = function(){
		
	}
	
	Connection.get_history_last = function(){
		
	}
	
	Connection.get_history_unread = function(){
		
	}
	
	Connection.init();
}

function update_conversatoin_list(conversatoin_data){
	console.log("draw_conversatoin_list");
	let div_html = conversatoin_data.reduce(function(div_html,item){
		let note = item.note &&  item.note.length>0
								?"<div class='note' title=''>"
									+"<div class='tooltip'>重要提醒"
										+"<span class='tooltiptext'>"
											+item.note.map(function(item){return item.msg;})+
										+"</span>"
									+"</div>"
								+"</div>"
								:"";
		
		div_html +=
				"<div class='list_element' customer_id='"+item.customer_id+"'>"
				+'		<div class="img" alt="">'
				+'			<img src="'+item.avator+'" alt="">'
				+'		</div>'
				+'		<div class="chat_body">'
				+'			<div class="title">'
				+					item.conversation_title
				+'			</div>'
				+'			<div class="msg">'
				+					item.last_message
				+'			</div>'
				+'		</div>'
				+			(item.unread?"<div class='unread'>"+item.unread+"</div>":"")
				+			note
				+'	</div>';
		return div_html;
	},"");
	
	$(".cs_manager_list_container").html(div_html);
	
}

//金牌話術
function talk_tricks_setting(data){
	
	let talk_tricks_str = data.map(function(item){
		return "<a class='talk_trick'>"+item+"</a>";
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
					then(function(stream) { 
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