//Only for cs_manager

$( function() {

	var conversation_list = [{"type":"CT200H","vehicle_id":"ABZ-1234","name":"王大明","avatar":"","unread":2,"latest_msg":[{"msg":"是的","time":"2019/09/20 10:11:50",}],"note":[{"msg":"生日"}],},{"type":"ES200","vehicle_id":"ABE-1234","name":"陳大為","avatar":"","unread":4,"latest_msg":[{"msg":"謝謝！！","time":"2019/09/18 14:05:03",}],"note":[{"msg":"保險到期日09/26"}],},{"type":"RX450H","vehicle_id":"ACE-8866","name":"林小東","avatar":"","unread":0,"latest_msg":[{"msg":"感謝您！","time":"2019/09/21 08:05:15",}],"note":[],},{"type":"GS300","vehicle_id":"LXS-8888","name":"吳小涵","avatar":"","unread":0,"latest_msg":[{"msg":"了解","time":"2019/09/15 18:35:07",}],"note":[],},{"type":"NX200","vehicle_id":"AAA-0000","name":"李小龍","avatar":"","unread":0,"latest_msg":[{"msg":"您已寄出一張圖片","time":"2019/09/17 12:00:44",}],"note":[],}];
	
	draw_conversation(conversation_list);
	
	$("#func_menu").click(function(){
	
		$("#func_list").toggle();
		$("#func_list").position({
		  my: "right-10 bottom-10",
		  at: "right top",
		  of: "#func_menu"
		});
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
				return "<p>"+note.msg+"</p>";
			});
			tr_container.append(
				$("<td/>").append(
					note_str
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