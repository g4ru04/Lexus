//Only for cs_manager

$( function() {

	$("#dialog-change-manager").dialog({autoOpen: false});
	$("#dialog-normal-talk-tricks").dialog({
		autoOpen: false,
		width: "420px"
	});

	//送出按鈕
	$(".btn-search").click(function(){
		send_text_msg();
	});
	
	$("input.input.msg").keypress(function(e) {
		if(e.which == 13) {
		   send_text_msg();
		}
	});
	
	//點擊note
	$(".list_element .note .tooltip").click(function(event){
		//頁面不觸發跳轉
		event.stopPropagation();
	});
	
	//List跳Dialog Dialog回到List
	$(".heder_service").click(function(){
		$(".cs_manager_list").toggleClass("current_view");
		$(".cs_manager_dialog").toggleClass("current_view");
		$(".cs_manager_list").toggleClass("hide_view");
		$(".cs_manager_dialog").toggleClass("hide_view");
	});
	
	$( ".cs_manager_list_container" ).delegate( ".list_element", "click", function() {

		$(".list_element").removeClass("active");
		$(this).addClass("active");
		let customer_id = $(this).attr("customer_id");
		let customer_name = $(this).find(".title").text().split("/").pop();
		$(".cs_manager_list").toggleClass("current_view");
		$(".cs_manager_dialog").toggleClass("current_view");
		$(".cs_manager_list").toggleClass("hide_view");
		$(".cs_manager_dialog").toggleClass("hide_view");
		if(Connection.client_id!=customer_id){
			Connection.change_customer(customer_id);
			$(".header_content .txt").html(customer_name);
			$("#console").html(
				'<div class="loading_div">'+
					'<img src="/images/loading.gif" />'+
				'</div>');
		}	
	});
	set_dialog_trigger();
} );

function apply_edit_nickname(event){
    targetevent = event;
	var target = event.srcElement.getAttribute('customer_id');

	Connection.socket.emit("edit customer name",{
		customer_id: target,
		manager_id: Connection.service_id,
		nickname: $('input[type="text"][customer_id="'+target+'"]').val()
	})

	$('input[customer_id="'+target+'"]').attr('style','display:none;');
	$('div.name[customer_id="'+target+'"]').attr('style','');
}

function edit_nickname(event){
    targetevent = event
	var target = event.srcElement.getAttribute('customer_id');
	$('div.name[customer_id="'+target+'"]').attr('style','display:none;');
	$('input[customer_id="'+target+'"]').attr('style','');
}

function edit_normal_trick(id, event) {
	//var element = null;
	if($('.txt').html() == "多人訊息"){
		if($('.dialog > div > #'+id).attr('type') == 'text'){
			var target = id.split('-');
			$('.dialog > div > #'+id).attr('onclick','select_trick(event)').attr('type','button');
			event.srcElement.value = "編輯";
			Connection.normal_talk_trick[target[2]] = $('.dialog > div > #'+id).val();
			Connection.update_talk_tricks('Normal', Connection.normal_talk_trick);
			
		}else{
			$('.dialog > div > #'+id).attr('onclick','').attr('type','text');
			event.srcElement.value = "確認";
		}

	}else{
		if($('#'+id).attr('type') == 'text'){
			var target = id.split('-');
			$('#'+id).attr('onclick','select_trick(event)').attr('type','button');
			event.srcElement.value = "編輯";
			Connection.normal_talk_trick[target[2]] = $('#'+id).val();
			Connection.update_talk_tricks('Normal', Connection.normal_talk_trick);
	
		}else{
			$('#'+id).attr('onclick','').attr('type','text');
			event.srcElement.value = "確認";
		}
	}
}
