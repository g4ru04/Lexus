
function emotion_setting(){
	let emotion_icon_list=['1f60a.png','1f60c.png','1f60d.png','1f60f.png','1f61a.png',
							'1f61c.png','1f61d.png','1f61e.png','1f62a.png','1f62d.png']
	let emotion_str = emotion_icon_list.map(function(icon_name){
		return `<a href='#' onclick="alert(\'${icon_name}\')">
			<img src='/images/${icon_name}'>
		</a>`;
	})
	$("#emoticon_container").html(emotion_str);
	
	$(".btn-laugh").click(function(){
		$("#emoticon_container").toggleClass("emotionIconOn"); 
	});
}

function produce_dialog_element(message) {
	console.log(message);
	if(message.from==null || message.message==null){
		return JSON.stringify(message,null,"    ")
				.replace(/    /g,"&nbsp;&nbsp;&nbsp;")
				.replace(/\n/g,"<br>")+"<br>";
	}
		
	let the_time = new Date(message.time);
	
	let message_str = "";
	if(message.message.type=="text"){
		message_str = message.message.text ;
		
	}else if(message.message.type=="image"){
		message_str += "<a target='_blank' href='"+message.message.url+"'>"
						+"<img src='"+message.message.url+"' style='height:60px;' />"
						+"</a>";
		
	}
	
	message_str += "<br>";
	
	if(message.intents && Connection.end_point=="service"){
		message.intents = message.intents.filter(function(item){
			return item.confidence>0.3;
		});
		if(message.intents.length!=0){
			message_str += "【"
				+message.intents.map(function(item){
					return item.intent+"("+
						new Number(item.confidence).toFixed(3)
					+") ";
				}).join(",")
			+"】";
		}else{
			message_str += "【無明確意圖】";
		}
	}
	if(message.recognitionResult && Connection.end_point=="service"){
		message_str += "【"+message.recognitionResult+"】";
	}
	
	
	return `<div class="dialog dialog--${message.type} clearfix">
		<div class="dialog__profile">
			<div class="dialog__profileImage"><img src="${message.from.avatar}"></div>
			<div class="dialog__profileName">${message.from.id}</div>
		</div>
		<div class="dialog__content">
			<div class="dialogPop">
				<p class="dialogPop__comment">${message_str}</p>
			</div>
			<div class="dialogTips">
				<div class="dialogTips__read"></div>
				<div class="dialogTips__time">${the_time.getHours()}:${the_time.getMinutes()}</div>
			</div>
		</div>
	</div>`;
}

//click or event 使用
function reiceive_msg(message){
	console.log(message);
	$("#console").append(produce_dialog_element(message));
	$("#console").scrollTop($('#console')[0].scrollHeight);
}

//click or event 使用
function send_text_msg(){
	
	if(Connection){
		Connection.send_text($("input.input.msg").val());
		$("input.input.msg").val('');
	}
	
}

//click or event 使用
function send_image_msg(url){
	
	if(Connection){
		Connection.send_image(url);
		$("input[type='file']").val('');
	}
	
}

function set_dialog(){
	let loading_bar = `
		<div class="loading_div">
			<img src="/images/loading.gif" />
		</div>
	`;
	$("#console").html(loading_bar);
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
			$("#console .loading_div").addClass("active");
			setTimeout(function(){
				$("#console .loading_div").removeClass("active")
			},2000);  
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