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
		
	});
	
} );
