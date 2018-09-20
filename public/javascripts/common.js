
function emotion_setting(){
	let emotion_icon_list=['1f60a.png','1f60c.png','1f60d.png','1f60f.png','1f61a.png',
							'1f61c.png','1f61d.png','1f61e.png','1f62a.png','1f62d.png']
	let emotion_str = emotion_icon_list.map(function(icon_name){
		return `<a href='#' onclick="alert(\'${icon_name}\')">
			<img src='/images/${icon_name}'>
		</a>`;
	})
	$("#emoticon_container").html(emotion_str);
	
	$("#emotionIcon").click(function(){
		$("#emoticon_container").toggleClass("emotionIconOn"); 
	});
}

function produce_dialog_element( type, name, avatar, message, read, time) {
	
	return `<div class="dialog dialog--${type} clearfix">
		<div class="dialog__profile">
			<div class="dialog__profileImage"><img src="${avatar}"></div>
			<div class="dialog__profileName">${name}</div>
		</div>
		<div class="dialog__content">
			<div class="dialogPop">
				<p class="dialogPop__comment">${message}</p>
			</div>
			<div class="dialogTips">
				<div class="dialogTips__read">${read}</div>
				<div class="dialogTips__time">${time}</div>
			</div>
		</div>
	</div>`;
}

function draw_dialog(dialog_data){

	let dialog_html = dialog_data.map(function(item){
		return produce_dialog_element(
			item.type,
			item.profile[0].name,
			item.profile[0].avatar,
			item.content[0].msg, 
			item.content[0].read,
			item.content[0].time
		);
	});
	$("#console").html(dialog_html);
}