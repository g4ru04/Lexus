//Only for cs_customer

$( function() {
	
	fetch('api/json/dl')
		.then(function(response) {
			return response.json();
		})
		.then(function(myJson) {
			draw_dialog(myJson);
		});
	
} );
