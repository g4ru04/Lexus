//need jquery && jquery-ui

$( function() {
	$( "#tabs" ).tabs();
	$( "#func_list" ).menu();
	
	emotion_setting();
	menu_setting();
	
	fetch('api/json/tl')
		.then(function(response) {
			return response.json();
		}).then(function(myJson) {
			talk_tricks_setting(myJson);
		}).catch(function(error) {
			console.log(error);
		});
	
});
function talk_tricks_setting(data){
	
	let talk_tricks_str = data.map(function(item){
		return `<a class='talk_trick'>${item}</a>`;
	}).join("");
	
	$("#talk_tricks_container").html(talk_tricks_str);
	
	$("#talk_tricks_container").delegate( ".talk_trick", "click", function() {
		$("#chat_text").val($(this).text());
	});
}

function menu_setting(){
	
	$("#func_menu").click(function(){
	
		$("#func_list").toggle();
		$("#func_list").position({
			my: "right-10 bottom-10",
			at: "right top",
			of: "#func_menu"
		});
		
	});
	
	$("#func_list").delegate( "li", "click", function() {
		$("#func_list").hide();
		if($(this).text()=="相機"){
			
			if (window.stream) {
				if (window.stream) {
					window.stream.getTracks().forEach(function(track) {
					  track.stop();
					});
				}
				window.stream = null;
				$("#video_container").html('<video autoplay=""> </video>');
				
			}else{
				navigator.mediaDevices.getUserMedia({ video: true}).
					then((stream) => { 
						window.stream = stream;
						document.querySelector('video').srcObject = stream;
					});	
			}
			
			$("#video_container").toggle();
			$("#video_container").position({
				my: "left+10 top+10",
				at: "left top",
				of: "#console"
			});
			
		}else if($(this).text()=="金牌話術"){
			$("#talk_tricks_container").toggleClass("enable"); 
		}else{
			alert($(this).text());
		}
	});
}