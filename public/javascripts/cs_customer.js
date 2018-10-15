//Only for cs_customer

$( function() {
	
	fetch('api/json/dl')
		.then(function(response) {
			return response.json();
		})
		.then(function(myJson) {
			draw_dialog(myJson);
		});
		
	$(".btn-search").click(function(){
		send_text_msg();
	});
	
	$("input.input.msg").keypress(function(e) {
		if(e.which == 13) {
		   send_text_msg();
		}
	});
} );
