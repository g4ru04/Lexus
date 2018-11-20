
function call_hotai_api(api_code,data,callback){
	console.log(api_code,data)
	var today = new Date();

	var apilog = {
		url: "HT_API_URL/" + api_code,
		start: today.toLocaleDateString('zh-tw') + ' ' + today.toLocaleTimeString('zh-tw'),
		end: "",
		success: "",
		data: ""
	};

	$.ajax({
		type : "POST",
		url : "/api",
		cache : false,
		contentType: 'application/json; charset=UTF-8',
		data : JSON.stringify({
			api: api_code,
			data:data,
			detail:true
		}),
		success: function(d) {
			console.log(api_code,d);
			
			today = new Date();
			apilog.end = today.toLocaleDateString('zh-tw') + ' ' + today.toLocaleTimeString('zh-tw');
			apilog.success = "Y";
			apilog.data = d;

			if(d.isSuccess){
				if(callback){
					callback(d.result);
				}
			}else{
				alert(d.result.rtnMsg || 'API取得失敗');
				console.log(d);
			}
		},error: function (jqXHR, textStatus, errorThrown) {
			alert('API使用異常:' + api_code);
			console.log(jqXHR,textStatus,errorThrown);
			
			today = new Date();
			apilog.end = today.toLocaleDateString('zh-tw') + ' ' + today.toLocaleTimeString('zh-tw');
			apilog.success = "N";
			apilog.data = textStatus;
		},complete: function() {
			try{
				Connection.api_log(apilog);
			}catch(e){
				io(socket_server_ip).emit("api log", apilog).close();
			}
        }
	});
	
}

function common_conn_setting(conn){
	
	//conn.client_id = 
	//		conn.client_id || (getUrlParameter("c")?b64DecodeUnicode(getUrlParameter("c")):UUID());
	conn.service_id = 
		conn.service_id || (getUrlParameter("s")?b64DecodeUnicode(getUrlParameter("s")):UUID());
	conn.conn = 
		conn.conn || (false) ;
	conn.talks = 
		conn.talk || ([]);
	conn.talks_history_cursor = 
		conn.talks_history_cursor || (0);
	
	conn.reiceive_msg =
		conn.reiceive_msg || function (message){
								$("#console").append(produce_dialog_element(message));
								$("#console").scrollTop($('#console')[0].scrollHeight);
							}
	
	conn.is_connect = function(){
		return conn.socket.connected;
	}
	conn.socket.on('disconnect', function () {
		my_console('已斷線');
	});
	
	conn.socket.on('message', function (data) {
		console.log("socket_event: message",data);
		conn.talks_history_cursor += 1;
		conn.talks.push(data);
		conn.reiceive_msg(data);
	});
	
	conn.socket.on('get history', function (data) {
		
		conn.talks_history_cursor += data.data.length;
		conn.talks = conn.talks.concat(data.data);
		//此為補上歷史資料
		data.data.sort(function(a,b){
			return b.time - a.time;
		});
		
		smoothly_set_history(JSON.parse(JSON.stringify(data.data)));

	});
	
	conn.send_text = function(message){
		//let service_icon = "https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png";
		//let client_icon = "/images/avatar.png";
		if(conn.client_id){
			conn.socket.emit("message", {
				"type": conn.end_point,
				"from": {
					"id": (conn.end_point=="service"?conn.service_id:conn.client_id),
					"name": (conn.end_point=="service"?conn.service_info.name:conn.client_info.name),
					"avator": (conn.end_point=="service"?conn.service_info.avator:conn.client_info.avator)
				},
				"to": {
					"id": (conn.end_point=="service"?conn.client_id:conn.service_id),
					"name": (conn.end_point=="service"?conn.client_info.name:conn.service_info.name),
					"avator": (conn.end_point=="service"?conn.client_info.avator:conn.service_info.avator)
				},
				"time": Date.now(),
				"message": {
					"type": "text",
					"text": message
				},
				"push":false
			});
		}else{
			alert('無對象');
		}
	}
	
	conn.send_image = function(url){
		//let service_icon = "https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png";
		//let client_icon = "/images/avatar.png";
		var item = {
			"type": conn.end_point,
			"from": {
				"id": (conn.end_point=="service"?conn.service_id:conn.client_id),
				"name": (conn.end_point=="service"?conn.service_info.name:conn.client_info.name),
				"avator": (conn.end_point=="service"?conn.service_info.avator:conn.client_info.avator)
			},
			"to": {
				"id": (conn.end_point=="service"?conn.client_id:conn.service_id),
				"name": (conn.end_point=="service"?conn.client_info.name:conn.service_info.name),
				"avator": (conn.end_point=="service"?conn.client_info.avator:conn.service_info.avator)
			},
			"time": Date.now(),
			"message": {
				"type": "image",
				"url": url
			},
			"push":false
		}
		console.log('img item:',item)
		conn.socket.emit("message", item);
	}
	
	conn.get_history = function(num){
		num = num?num:10;
		if(!conn.getting_history){
			conn.getting_history = true;
			$("#console .loading_div").addClass("active");
			conn.socket.emit("get history",{
				"skip": conn.talks_history_cursor,
				"limit":num
			});
		}
	}

	//melvin
	conn.group_send = function(msg_obj){
		msg_obj.push = true;
		console.log('msg_obj',msg_obj)
		conn.socket.emit("message", msg_obj);
	}
	conn.api_log = function(log){
		Connection.socket.emit("api log", log);
	}
}

function emotion_setting(){
	let emotion_icon_list=['1f60a.png','1f60c.png','1f60d.png','1f60f.png','1f61a.png',
							'1f61c.png','1f61d.png','1f61e.png','1f62a.png','1f62d.png']
	let emotion_str = emotion_icon_list.map(function(icon_name){
		return '<a href="#" class="emotion_icon" icon_name="'+icon_name+'">'
			+'<img src="/images/'+icon_name+'">'
		+'</a>';
	})
	$("#emoticon_container").delegate( ".emotion_icon", "click", function() {
		Connection.send_image(location.origin+'/images/'+$(this).attr("icon_name"));
		$("#emoticon_container").toggleClass("emotionIconOn"); 
	});

	$("#emoticon_container").html(emotion_str);
	
	$(".btn-laugh").click(function(){
		$("#emoticon_container").toggleClass("emotionIconOn"); 
	});
}

function produce_dialog_element(message) {
	if(message.from==null || message.message==null){
		return JSON.stringify(message,null,"    ")
				.replace(/    /g,"&nbsp;&nbsp;&nbsp;")
				.replace(/\n/g,"<br>")+"<br>";
	}
		
	let the_time = new Date(message.time);
	
	let message_str = "";
	if(message.message.type=="text"){
		message_str = message.message.text
						.replace(/\n/g,"<br>") ;
		
	}else if(message.message.type=="image"){
		message_str += "<a target='_blank' href='"+message.message.url+"'>"
						+"<img src='"+message.message.url+"' style='height:60px;' />"
						+"</a>";
		
	}
	
	message_str += "<br>";
	
	// if(message.intents && Connection.end_point=="service"){
	// 	message.intents = message.intents.filter(function(item){
	// 		return item.confidence>0.3;
	// 	});
	// 	if(message.intents.length!=0){
	// 		message_str += "【"
	// 			+message.intents.map(function(item){
	// 				return item.intent+"("+
	// 					new Number(item.confidence).toFixed(3)
	// 				+") ";
	// 			}).join(",")
	// 		+"】";
	// 	}else{
	// 		message_str += "【無明確意圖】";
	// 	}
	// }
	if(message.recognitionResult && Connection.end_point=="service"){
		message_str += "【"+message.recognitionResult+"】";
	}
	/*
	let from_info = {name:"SOMEONE",avator:"/images/avatar.png"};
	if(message.from.id == Connection.client_info.id){
		from_info = Connection.client_info;
	}
	if(message.from.id == Connection.service_info.id){
		from_info = Connection.service_info;
	}*/
	
	return '<div class="dialog dialog--'+message.type+' clearfix">'
		+'<div class="dialog__profile">'
		+'	<div class="dialog__profileImage"><img src="'+message.from.avator+'"></div>'
		+'	<div class="dialog__profileName">'+message.from.name+'</div>'
		+'	</div>'
		+'	<div class="dialog__content">'
		+'		<div class="dialogPop">'
		+'			<p class="dialogPop__comment">'+message_str+'</p>'
		+'		</div>'
		+'		<div class="dialogTips">'
		+'			<div class="dialogTips__read"></div>'
		+'			<div class="dialogTips__time">'
		+				displayChatTime(the_time)
		+'			</div>'
		+'		</div>'
		+'	</div>'
		+'</div>';
}

function smoothly_set_history(data){
	if(data.length>0){
		setTimeout(function(){
			let item = data.shift();
			$("#console .loading_div").after(
				produce_dialog_element(item)
			);
			smoothly_set_history(data)
		},100);
	}else{
		Connection.getting_history = false;
		$("#console .loading_div").removeClass("active")
	}
}

function my_console(message){
	$("#console").append(produce_dialog_element(message));
	$("#console").scrollTop($('#console')[0].scrollHeight);
}

//click or event 使用
function send_text_msg(){
	
	if(Connection&&$("input.input.msg").val().length>0){
		Connection.send_text($("input.input.msg").val());
		$("input.input.msg").val('');
	}
	
}

function save_picture(){
	
	let file_val = $('#upload_picture').val();
	let validExts = [".png",".jpg",".jpeg",".gif",".bmp"];
	let file_ext = file_val.substring(file_val.lastIndexOf('.'))
	if (validExts.indexOf(file_ext.toLowerCase()) < 0) {
		$('#upload_picture').val('');
		alert("只接受此類圖片檔案：" + validExts.join(", "));
		return ;
	}
	
	var data = new FormData();
    $.each($('#upload_picture')[0].files, function(i, file) {
        data.append('file-'+i, file);
    });
	$.ajax({
		url: '/upload',
		type: 'POST',
		data: data,
		cache: false,
        contentType: false,
        processData: false,
        method: 'POST',
		success: function(data){
			if(data.status=="success"){
				send_image_msg(data.url);
			}else{
				alert("檔案上傳失敗");
			}
		},
		error: function(xhr, status, error) {
			console.log(xhr);
			console.log(status);
			console.log(error);
		}
	});
}

//click or event 使用
function send_image_msg(url){
	
	if(Connection){
		Connection.send_image(url);
		$("input[type='file']").val('');
	}
	
}

function set_dialog_trigger(){
	//讀歷史紀錄trigger
	let element = document.getElementById("console");
	if(navigator.userAgent.indexOf("Firefox") !== -1){
		element.addEventListener("DOMMouseScroll",wheelHandler,false);
	}
	element.onmousewheel = wheelHandler;

	function wheelHandler(event){ 
		event = event || window.event; 
		var delta = event.wheelDelta || event.detail*-30;
		if(delta>0 && $("#console").scrollTop()==0){
			Connection.get_history();
		}
	}
	
	$("#console").on("touchstart", function(e) {
		// 判断默认行为是否可以被禁用
		if (e.cancelable) {
			// 判断默认行为是否已经被禁用
			if (!e.defaultPrevented) {
				e.preventDefault();
			}
		}   
		startX = e.originalEvent.changedTouches[0].pageX,
		startY = e.originalEvent.changedTouches[0].pageY;
	});
	
	$("#console").on("touchmove", function(e){
		if (e.cancelable) {
			// 判断默认行为是否已经被禁用
			if (!e.defaultPrevented) {
				e.preventDefault();
			}
		}               
		moveEndX = e.originalEvent.changedTouches[0].pageX,
		moveEndY = e.originalEvent.changedTouches[0].pageY,
		X = moveEndX - startX,
		Y = moveEndY - startY;
		if ( Y > 0 ) {
			Connection.get_history();
		}
		
	});
	
}

function warningMsg(title, msg) {
	$("<div/>").html(msg).dialog({
		title: title,
		draggable : true, resizable : false, autoOpen : true,
		height : "auto", width : "240", modal : true,
		buttons : [{
			text: "確定", 
			click: function() { 
				$(this).dialog("close");
			}
		}]
	});
}

function displayChatTime(time){
	let the_time = new Date(time);
	return (Array(2).join("0") +the_time.getHours()).slice(-2) +":"+ (Array(2).join("0") +the_time.getMinutes()).slice(-2)
}

function getUrlParameter(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

function b64EncodeUnicode(str) {
    return btoa(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, function(match, p1) {
        return String.fromCharCode('0x' + p1);
    }));
}

function b64DecodeUnicode(str) {
    return decodeURIComponent(Array.prototype.map.call(atob(str), function(c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join(''));
}

function UUID(){
	return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
	    var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
	    return v.toString(16);
	});
}

function post(path, params, method) {
	method = method || "post";
	var form = document.createElement("form");
	form.setAttribute("method", method);
	form.setAttribute("action", path);

	for(var key in params) {
		if(params.hasOwnProperty(key)) {
			var hiddenField = document.createElement("input");
			hiddenField.setAttribute("type", "hidden");
			hiddenField.setAttribute("name", key);
			hiddenField.setAttribute("value", params[key]);

			form.appendChild(hiddenField);
		}
	}

	document.body.appendChild(form);
	form.submit();
}