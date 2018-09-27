//Only for cs_manager

$( function() {

	fetch('api/json/dl')
		.then(function(response) {
			return response.json();
		}).then(function(myJson) {
			draw_dialog(myJson);
		}).catch(function(error) {
			console.log(error);
		});
	
} );
