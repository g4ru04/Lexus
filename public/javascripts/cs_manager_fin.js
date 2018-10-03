//Only for cs_manager

$( function() {

	fetch('api/json/d2')
		.then(function(response) {
			return response.json();
		}).then(function(myJson) {
			draw_dialog(myJson);
		}).catch(function(error) {
			console.log(error);
		});
	
} );
