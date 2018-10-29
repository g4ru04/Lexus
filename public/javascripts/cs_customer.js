//Only for cs_customer

$( function() {
	
	set_dialog_trigger();
	
	$(".btn-search").click(function(){
		send_text_msg();
	});
	
	$("input.input.msg").keypress(function(e) {
		if(e.which == 13) {
		   send_text_msg();
		}
	});
	$(".btn-picture").click(function(){
		$("#upload_picture").trigger("click"); 
	});
	
} );

