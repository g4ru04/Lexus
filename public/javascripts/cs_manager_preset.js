//need jquery && jquery-ui

$( function() {
	$( "#tabs" ).tabs();
	
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
	
	$(".list_element , .heder_service").click(function(){
		let customer_name = $(this).find(".title").text().split("/").pop();
		console.log(customer_name);
		$(".cs_manager_list").toggleClass("current_view");
		$(".cs_manager_dialog").toggleClass("current_view");
		$(".cs_manager_list").toggleClass("hide_view");
		$(".cs_manager_dialog").toggleClass("hide_view");
		if(customer_name!=""){
			$(".dialog--client .dialog__profileName").text(customer_name);
			$(".header_content .txt").html(customer_name);
		}
		
	});
	$(".btn-search").click(function(){
		console.log($(".input").val());
	});
});
function talk_tricks_setting(data){
	
	let talk_tricks_str = data.map(function(item){
		return `<a class='talk_trick'>${item}</a>`;
	}).join("");
	
	$("#talk_tricks_container").html(talk_tricks_str);
	
	$("#talk_tricks_container").delegate( ".talk_trick", "click", function() {
		$(".input").val($(this).text());
	});
}

function menu_setting(){
	
	$(".btn-add").click(function(){
		$(".select-menu").toggle();
	});
	
	$(".select-menu a").click(function(){
		let func_name = $(this).text().trim();
		if(func_name=="相機"){
			
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
			
		}else if(func_name=="金牌話術"){
			$("#talk_tricks_container").toggleClass("enable"); 
		}else{
			alert(func_name);
		}
		
		$(".select-menu").toggle();
	});
}