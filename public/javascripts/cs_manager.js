//Only for cs_manager

$( function() {

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
	
	$(".list_element").click(function(){
		
		let customer_id = $(this).attr("customer_id");
		let customer_name = $(this).find(".title").text().split("/").pop();
		Connection.change_customer(customer_id);
		
		$(".cs_manager_list").toggleClass("current_view");
		$(".cs_manager_dialog").toggleClass("current_view");
		$(".cs_manager_list").toggleClass("hide_view");
		$(".cs_manager_dialog").toggleClass("hide_view");
	
		$(".dialog--client .dialog__profileName").text(customer_name);
		$(".header_content .txt").html(customer_name);
		
		$("#console").html('<div class="loading_div"><img src="/images/loading.gif"></div><div class="dialog dialog--service clearfix"><div class="dialog__profile"><div class="dialog__profileImage"><img src="/images/avatar.png"></div><div class="dialog__profileName">服務專員</div></div><div class="dialog__content"><div class="dialogPop"><p class="dialogPop__comment">您好！</p></div><div class="dialogTips"><div class="dialogTips__read"></div><div class="dialogTips__time">14:55</div></div></div></div><div class="dialog dialog--client clearfix"><div class="dialog__profile"><div class="dialog__profileImage"><img src="/images/avatar.png"></div><div class="dialog__profileName">'+customer_name+'</div></div><div class="dialog__content"><div class="dialogPop"><p class="dialogPop__comment">我想要ES的型錄！</p></div><div class="dialogTips"><div class="dialogTips__read"></div><div class="dialogTips__time">14:55</div></div></div></div><div class="dialog dialog--service clearfix"><div class="dialog__profile"><div class="dialog__profileImage"><img src="/images/avatar.png"></div><div class="dialog__profileName">服務專員</div></div><div class="dialog__content"><div class="dialogPop"><p class="dialogPop__comment">好的，馬上為您準備車款資訊！</p></div><div class="dialogTips"><div class="dialogTips__read"></div><div class="dialogTips__time">14:55</div></div></div></div>');
		
	});
	
} );
