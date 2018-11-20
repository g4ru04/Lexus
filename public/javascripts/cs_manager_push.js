
//melvin
getUserList = function(){
	fetch('api/json/sl')
	.then(function(response) {
		return response.json();
	})
	.then(function(data) {
		showUserList(data);
	})
	.catch(function(error) {
		console.error(error);
	});
}
 showUserList = function(data){
}
 showGroupSend = function(){
	getUserList();
	initFroalaEditor();
	gs_edit_setting();
}
gs_edit_setting = function() {
	var title = $('.txt').html();
	$('.txt').html('多人訊息');

	$('.btn_gs_leave').unbind('click');
	$('.btn_gs_leave').click(function(e){
		$('.txt').html(title);
		$(".cs_manager_dialog, .gs_area, .btn_gs_choose")
			.addClass("current_view")
			.removeClass("hide_view");
		$('.gs, .gs_list, .btn_gs_submit, .btn_gs_reset')
			.addClass('hide_view')
			.removeClass('current_view');
	});

	$(".gs_list, .btn_gs_submit")
		.removeClass("current_view")
		.addClass("hide_view");
 	$('.gs, .gs_area, .btn_gs_choose, .btn_gs_reset')
		.removeClass('hide_view')
		.addClass('current_view');
}
gs_list_setting = function(name_filter,birth_filter,insurance_filter) {
	
	let gs_conversation_list = Connection.conversation_list;
	if(name_filter && name_filter!=""){
		gs_conversation_list = gs_conversation_list.filter(function(item){
			let input = $("#gs_fliter").val();
			return item.conversation_title.includes(input) || item.customer_nickname.includes(input);
			//let input = $("")
			//return item.conversation_title.includes(input) || item.customer_nickname.includes(input)
		})
	}
	if(birth_filter){
		gs_conversation_list = gs_conversation_list.filter(function(item){
			return DateDiff(item.detail.BRTHDT) < 15;//TODO
			//return (new Date(item.OOXX).getTime() - Date.now()) >14 * 24*60*60*1000;
		})
	}
	if(insurance_filter){
		gs_conversation_list = gs_conversation_list.filter(function(item){
			return DateDiff(item.detail.FENDAT) < 15;//TODO
			//return (new Date(item.OOXX).getTime() - Date.now()) >14 * 24*60*60*1000;
		})
	}
	$('#gs_list').html(gs_conversation_list.reduce(function(result,item){
		//以下原code
		return result + '<div class="list_element" customer_id="' + item.customer_id + '">'+
		'	<div class="img" alt="">'+
		'		<img src="' + item.avator + '" alt="">'+
		'	</div>'+
		'	<div class="chat_body">'+
		'		<div class="title">'+
		'			<input type="checkbox" id="' + item.customer_id + '" />'+
		'			<label for="' + item.customer_id + '">' +
		'			' + item.conversation_title + '/' + item.customer_nickname +
		'			</label>'+
		'		</div>'+
		'	</div>'+
		'</div>';
	},""));
	$(".cs_manager_dialog, .gs_area, .btn_gs_choose")
		.removeClass("current_view")
		.addClass("hide_view");
 	$('.gs, .gs_list, .btn_gs_submit, .btn_gs_reset')
		.removeClass('hide_view')
		.addClass('current_view');
}

$('.btn_gs_reset').click(function(e){
	gs_edit_setting();
})
$('.btn_gs_choose').click(function(e){
	e.preventDefault();
	gs_list_setting();
})
initFroalaEditor = function(){
	$('img#gs_photo').froalaEditor({
		height: 30,
		imageUploadParam: 'file',
		imageUploadURL: '/upload_image',
		imageUploadMethod: 'POST',
		imageMaxSize: 5 * 1024 * 1024,
		imageAllowedTypes: ['jpeg', 'jpg', 'png']
	})
	.on('froalaEditor.image.uploaded', function (e, editor, response) {
		let res = JSON.parse(response);
		// $('img#gs_photo').attr('src', res.link);
		// Image was uploaded to the server.
	});
	$('textarea').froalaEditor();
	
}
$('.gs .btn_gs_submit').click(function(e){
	e.preventDefault();
	
	let userlist = [];
	let msg = $('#gs_form .gs_msg').val(),
		url = $('#gs_photo').attr('src');
	
	$('#gs_list :checkbox:checked').each(function(idx, element){
		userlist.push($(element).attr('id'));
	});
 	if(userlist.length == 0 || msg == ""){
		alert('請挑選車主並填寫訊息。');
		return;
	}
 	userlist.forEach(function(element) {
		let message_obj = {
			type: "service",
			from: {
				id: Connection.service_id,
				name: Connection.service_info.name,
				avatar: "https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png",
			},
			to: {
				id: element,
				name: Connection.client_info.name,
				avatar: "/images/avatar.png"
			},
			time: Date.now(),
			message: {
				type: "text",
				text: msg
			}
		},
		image_obj = {
			type: "service",
			from: {
				id: Connection.service_id,
				avatar: "https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png",
			},
			to: {
				id: element,
				avatar: "/images/avatar.png"
			},
			time: Date.now(),
			message: {
				type: "image",
				url: url
			}
		};
		
		Connection.group_send(message_obj);
		if(url) Connection.group_send(image_obj);

		//推播
 		line_push_message_obj = {
			COMPID: "AY",
			USERID: "AY04916",
			MSG: "您有一封來自車主的訊息，請登入https://htsr.hotaimotor.com.tw/LINENOTIFYAPI_TEST/LOGIN/login查看"
		};
		
		//call_hotai_api("API",{},function(){});

 		// $.post('line_send_message', line_push_message_obj, function(result){
		// 	return result;
		// });
		
		$('.btn_gs_leave').trigger('click');
	});
}) 

//filter
$('.push_search_box_container > input[type="text"]').keyup(function(e){
	gs_refresh_list();
});
$('.push_search_box_container > input[name="birth_filter"]').change(function(e){
	gs_refresh_list();
});
$('.push_search_box_container > input[name="insurance_filter"').change(function(e){
	gs_refresh_list();
});
gs_refresh_list = function(){
	let name_filter = $('.push_search_box_container > input[type="text"]').val();
	let birth_filter = $('.push_search_box_container > input[name="birth_filter"]').prop("checked");
	let insurance_filter = $('.push_search_box_container > input[name="insurance_filter"]').prop("checked");
	gs_list_setting(name_filter,birth_filter,insurance_filter);
}