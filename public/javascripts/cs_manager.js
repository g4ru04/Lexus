//Only for cs_manager

$( function() {

	fetch('api/json/sl')
		.then(function(response) {
			return response.json();
		}).then(function(myJson) {
			draw_conversation(myJson);
		}).catch(function(error) {
			console.log(error);
		});
		
	fetch('api/json/dl')
		.then(function(response) {
			return response.json();
		}).then(function(myJson) {
			draw_dialog(myJson);
		}).catch(function(error) {
			console.log(error);
		});
	
} );

//三個tab共用 以參數tab_name區隔
function draw_for_different_tab(conversation_data,tab_name){

	//不同TAB資料篩選
	if(tab_name=="tabs_all"){
		
	}else if(tab_name=="tabs_unread"){
		conversation_data = conversation_data.filter(function(item){
			if(item.unread>0){
				return true;
			}
		})
	}else if(tab_name=="tabs_note"){
		conversation_data=conversation_data.filter(function(item){
			if(item.note.length>0){
				return true;
			}
		})
	}
	
	//排序對話框時間
	conversation_data.sort(function(a,b){
		if(a.latest_msg[0].time < b.latest_msg[0].time){
			return true;
		}else if(a.latest_msg[0].time > b.latest_msg[0].time){
			return false;
		}
	});
	
	
	//畫出Tab內容
	let container = conversation_data.reduce(function( table_container, element) {
		
		let tr_container= $("<tr/>");
		tr_container.append([
			$("<td/>").append(
				$("<img/>",{
					"src":element.avatar,
					"class":"avatar"
				})
			),
			$("<td/>").append(
				$("<p/>").text( element.type + " / " + element.vehicle_id + " / " + element.name),
				$("<p/>").text( element.latest_msg[0].msg)
			)
		]);
		
		//畫出Tab最後一欄
		if( tab_name=="tabs_all" ){
			
		}else if( tab_name=="tabs_unread" ){
			tr_container.append(
				$("<td/>").append(
					$("<p/>",{
						"class":"unread"
					}).text(
						element.unread
					)
				)
			)
		}else if( tab_name=="tabs_note" ){
			let note_str = element.note.map(function( note){
				return note.msg;
			});
			tr_container.append(
				$("<td/>").append(
					$("<p/>",{
						"class":"note"
					}).text(
						note_str
					)
				)
			)
		}
		
		table_container.append(
			tr_container
		);
		
		return table_container;
	},$("<table/>"));
	
	return container.prop("outerHTML");
}


function draw_conversation(conversation_list){
	
	$("#tabs_all").html(
		draw_for_different_tab(conversation_list, "tabs_all")
	);
	$("#tabs_unread").html(
		draw_for_different_tab(conversation_list, "tabs_unread")
	);
	$("#tabs_note").html(
		draw_for_different_tab(conversation_list, "tabs_note")
	);
	
}