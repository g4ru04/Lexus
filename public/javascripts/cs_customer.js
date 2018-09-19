//Only for cs_customer

$( function() {

	var conversation_list = [{"name":"銷售專員","avatar":"","unread":0,"latest_msg":[{"msg":"好的，馬上為您準備車款資訊！","time":"2019/09/20 10:11:50"}],"note":[{"msg":"生日"}]},{"name":"服務專員","avatar":"","unread":1,"latest_msg":[{"msg":"下次見！！","time":"2019/09/18 14:05:03"}]}];
	
	draw_conversation(conversation_list);
	
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
				$("<p/>").text( element.name ),
				$("<p/>").text( element.latest_msg[0].msg )
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
	
}
