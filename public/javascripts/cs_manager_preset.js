//need jquery && jquery-ui

$( function() {
	
	emotion_setting();
	menu_setting();
	
	
	set_manager_socket();
	$("#talk_tricks_container").delegate( ".talk_trick", "click", function() {
		$(".input").val($(this).text());
		$("#talk_tricks_container").toggleClass("enable"); 
	});
	$("#talk_tricks_container").delegate( ".talk_tricks_edit", "click", function() {
		let talk_trick_text = [];
		$(".talk_tricks_edit").parent().find(".talk_trick").each(function(i,item){
			talk_trick_text.push($(item).text());
		});
		
		let editor_str = talk_trick_text.map(function(item){
			return "<div>"+
				"<input type='text' value='"+item+"' />"+
				"&nbsp;<span class='del'>DELETE</span>"+
				"</div>"
		}).join("<br>");
		console.log(talk_trick_text);
		console.log(talk_trick_text);
		
		$("#talk_tricks_editor").html(editor_str+"<div class='new'>new</div>");
		$("#talk_tricks_editor").dialog( "open" );
		
		
		$(".input").val($(this).text());
		$("#talk_tricks_container").toggleClass("enable"); 
	});
	$("#talk_tricks_editor").delegate( ".del", "click", function() {
		$(this).parent().remove();
	});
	$("#talk_tricks_editor").delegate( ".new", "click", function() {
		$(this).before("<br>");
		$(this).before(
			"<div>"+
			"<input type='text' value='' />"+
			"&nbsp;<span class='del'>DELETE</span>"+
			"</div>"
		)
		
	});
	$("#talk_tricks_editor").dialog({
			title: "修改相應回答話術",
			draggable : true, resizable : false, autoOpen : false,
			height : "auto", width : "600", modal : true,
			buttons : [{
				text: "修改", 
				click: function() { 
					$(this).dialog("close");
					let ans_ID = $("#talk_tricks_editor").attr("ans_ID");
					let talk_tricks = [];
					$("#talk_tricks_editor").find("input").each(function(i,item){
						talk_tricks.push($(item).val());
					})

					Connection.update_talk_tricks(ans_ID,talk_tricks);
				}
			},{
				text: "取消", 
				click: function() { 
					$(this).dialog("close");
				}
			}]
		});
	
});

//設定 Socket 
function set_manager_socket(){
	
	Connection = {}
	
	Connection.init = function(){
		Connection.socket = io(socket_server_ip);
		
		Connection.end_point = "service" ;
		Connection.client_id  = "";
		Connection.service_id = getUrlParameter("s")?b64DecodeUnicode(getUrlParameter("s")):UUID();
		Connection.conn = false ;
		Connection.talks = [];
		Connection.talks_history_cursor = 0;
		
		Connection.set_listener();
		
		common_conn_setting(Connection);
		
		Connection.socket.emit("register service",{
			type : Connection.end_point,
			service_id : Connection.service_id,
		});
	}
	
	Connection.set_listener = function(){
		Connection.socket.on('enter', function (data) {
			Connection.conn = true;
			my_console("【"+Connection.client_id+"-"+Connection.service_id+"】 連線成功");
			Connection.socket.emit("get history",{});
		});
	
		Connection.socket.on('leave', function () {
			console.log("leave: "+Connection.client_id);
			console.log("join: "+Connection.next_client_id);
			if(Connection.next_client_id){
				Connection.socket.emit("enter", {
					type : Connection.end_point,
					client_id : Connection.next_client_id,
					service_id : Connection.service_id
				});
			}
			Connection.client_id = Connection.next_client_id;
			Connection.next_client_id = null;
		});
		
		Connection.socket.on('reconnect', function () {
			Connection.conn = true;
			my_console("重新連接");
			$("#console").html('<div class="loading_div"><img src="/images/loading.gif" /></div>');
			Connection.socket.emit("enter",{
				type : Connection.end_point,
				client_id : Connection.client_id,
				service_id : Connection.service_id,
			});
			Connection.socket.emit("register service",{
				type : Connection.end_point,
				service_id : Connection.service_id,
			});
		});
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
	
	Connection.reiceive_msg = function (message){
		
		if(message.ans_ID){
			$("#talk_tricks_editor").attr("ans_ID",message.ans_ID);
		}
		if(message.talk_tricks){
			talk_tricks_setting(message.talk_tricks);
			$("#talk_tricks_container").addClass("enable"); 
		}
		$("#console").append(produce_dialog_element(message));
		$("#console").scrollTop($('#console')[0].scrollHeight);
	}
	
	Connection.update_talk_tricks = function(ans_ID,talk_tricks){
		console.log("update talk trick");
		console.log(ans_ID);
		console.log(talk_tricks);
		Connection.socket.emit('update talk trick',{
			dialog_id : ans_ID,
			talk_tricks : talk_tricks
		});
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
				"<div class='list_element "+(Connection.client_id == item.customer_id?"active":"")+"'"
				+"		 customer_id='"+item.customer_id+"'>"
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
				+			"<div class='timestamp'>"+displayChatTime(item.last_talk_time)+"&nbsp;</div>"
				+			(item.unread?"<div class='unread'>"+item.unread+"</div>":"")
				+			note
				+'	</div>';
		return div_html;
	},"");
	
	$(".cs_manager_list_container").html(div_html);
	
}

//金牌話術
function talk_tricks_setting(data){
	
	let edit_div = "<div class='talk_tricks_edit'></div>";
	let talk_tricks_str = data.map(function(item){
		return "<div class='talk_trick'><a>"+item+"</a></div>";
	}).join("");
	
	$("#talk_tricks_container").html( edit_div + talk_tricks_str );
	
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
		}else if(func_name=="撥打電話"){
			location.href = 'tel:+886-919863010';
			
		}else if(func_name=="照片"){
			$("#upload_picture").trigger("click"); 
			
		}else if(func_name=="金牌話術"){
			$("#talk_tricks_container").toggle();

		}else{
			alert(func_name);
		}
		
		$(".select-menu").toggle();
	});
}