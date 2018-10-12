
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

function produce_dialog_element(item) {
	let the_time = new Date(item.content[0].time);
	return `<div class="dialog dialog--${item.type} clearfix">
		<div class="dialog__profile">
			<div class="dialog__profileImage"><img src="${item.profile[0].avatar}"></div>
			<div class="dialog__profileName">${item.profile[0].name}</div>
		</div>
		<div class="dialog__content">
			<div class="dialogPop">
				<p class="dialogPop__comment">${item.content[0].msg}</p>
			</div>
			<div class="dialogTips">
				<div class="dialogTips__read">${item.content[0].read}</div>
				<div class="dialogTips__time">${the_time.getHours()}:${the_time.getMinutes()}</div>
			</div>
		</div>
	</div>`;
}

function draw_dialog(dialog_data){
	
	let loading_bar = `
		<div class="loading_div">
			<img src="/images/loading.gif" />
		</div>
	`;
	let dialog_html = dialog_data.map(function(item){
		return produce_dialog_element(item);
	}).join("");
	$("#console").html(loading_bar + dialog_html);
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