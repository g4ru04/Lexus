//Only for cs_manager

$( function() {

	fetch('api/json/sl')
		.then(function(response) {
			return response.json();
		})
		.then(function(myJson) {
			draw_conversation(myJson);
		});
		
	fetch('api/json/dl')
		.then(function(response) {
			return response.json();
		})
		.then(function(myJson) {
			draw_dialog(myJson);
		});
	
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
		alert($(this).text());
		
	});
	
} );

function produce_dialog_element( type, name, avatar, message, read, time) {
	console.log("produce_dialog_element");
	return `<div class="dialog dialog--${type} clearfix">
		<div class="dialog__profile">
			<div class="dialog__profileImage"><img src="${avatar}"></div>
			<div class="dialog__profileName">${name}</div>
		</div>
		<div class="dialog__content">
			<div class="dialogPop">
				<p class="dialogPop__comment">${message}</p>
			</div>
			<div class="dialogTips">
				<div class="dialogTips__read">${read}</div>
				<div class="dialogTips__time">${time}</div>
			</div>
		</div>
	</div>`;
}

function draw_dialog(dialog_data){

	let dialog_html = dialog_data.map(function(item){
		return produce_dialog_element(
			item.type,
			item.profile[0].name,
			item.profile[0].avatar,
			item.content[0].msg, 
			item.content[0].read,
			item.content[0].time
		);
	});
	$("#console").html(dialog_html);
}


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