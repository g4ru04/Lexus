//need jquery && jquery-ui

$( function() {
	emotion_setting();
	maintain_log_init();
	
	set_customer_socket();
	
	$("#dialog").dialog({autoOpen: false});
	$(".header_content .txt").html(Connection.service_name);
});

//設定 Socket 
function set_customer_socket(){
	
	Connection = {}
	
	Connection.init = function(manager_id){
		Connection.socket = io(socket_server_ip);
		
		Connection.end_point = "client" ;
		Connection.client_id  = client_id_b64?b64DecodeUnicode(client_id_b64):UUID();
		Connection.service_id = manager_id?manager_id:service_id_b64?b64DecodeUnicode(service_id_b64):UUID();
		Connection.client_info = {
			"id":"",
			"name":"",
			"avator":"/images/avator.png",
			"PHONE":""
		};
		Connection.service_info = {
			"id":"",
			"name":"",
			"avator":"/images/avator.png",
			"PHONE":""
		};;
		Connection.conn = false ;
		Connection.talks = [];
		Connection.talks_history_cursor = 0;
		
		Connection.set_listener();
		common_conn_setting(Connection);
		
		Connection.socket.emit("enter", {
			type : Connection.end_point,
			client_id : Connection.client_id,
			service_id : Connection.service_id
		});
		
	}
	
	Connection.set_listener = function(){
		
		Connection.socket.on('enter', function (data) {
			try {
				let conversation_data = data[0][0];
				Connection.client_info = JSON.parse(conversation_data.customer_data);
				Connection.service_info = JSON.parse(conversation_data.manager_data);
				
			}catch(err) {
				console.log(err);
			}
			console.log("Connection.service_info",Connection.service_info);
			console.log("Connection.client_info",Connection.client_info);
			
			Connection.conn = true;
			my_console("【"+Connection.client_id+"-"+Connection.service_id+"】 連線成功");
			Connection.socket.emit("register client",{});
			if(Connection.talks_history_cursor==0){
				Connection.socket.emit("get history",{});
			}
		});
		
		Connection.socket.on('reconnect', function () {
			Connection.conn = true;
			my_console("重新連接");
			//$("#console").html('<div class="loading_div"><img src="/images/loading.gif" /></div>');
			Connection.socket.emit("enter", {
				type : Connection.end_point,
				client_id : Connection.client_id,
				service_id : Connection.service_id
			});
		});

		Connection.socket.on('change customer',function(data){
			console.log('change customer',data)
			if(data.manager_id !== Connection.service_id){
				Connection.socket.emit("leave",{});
				Connection.init(data.manager_id);
			}
		})
	}
	
	Connection.reiceive_msg = function (message){
		$("#console").append(produce_dialog_element(message));
		$("#console").scrollTop($('#console')[0].scrollHeight);
	}
	
	Connection.init();

}

function maintain_log_init(){
	$('#maintain_log').click(function(){
		$("#dialog").dialog("open");
	})
	
	$("#maintain-return").click(function(){
		$('#maintain-page').toggle();
	});
	$("#detail-return").click(function(){
		$('#detail-page').toggle();
	});
}

function moredetail(DLRCD,BRNHCD,WORKNO,RTPTDT,RTPTML,TOTAMT){
	call_hotai_api("LINELCS03_Q02",{  
		"DLRCD": DLRCD,
		"BRNHCD": BRNHCD,
		"WORKNO": WORKNO
	},function(data){
		$('#detail-no').html("工單編號: " + WORKNO);
		$('#detail-date').html("入廠日期: " + RTPTDT);
		$('#detail-kms').html("入廠里程: " + RTPTML);
		$('#detail-amt').html("發票金額:  " + TOTAMT);

		var list = data.PARTSDATA.map(function(item){
			return '<div class="list_element">'+
			'	<div class="list-table">' +
			'		<div class="list-tr">' +
			'			<div class="list-cell">' + item.PTCHNM + '</div>' +
			'			<div class="list-cell">數量：' + item.PCNT + ' 單位</div>' +
			'		</div>' +
			'	</div>' +
			'</div>';
		}).join('');

		$('#maintain_details').html(list);
		$('#detail-page').toggle();
	});
}

function do_login(){
	call_hotai_api("LINE001_Q01",{
		"LICSNO": Connection.client_info.vehicle_number,
		//todo 確認這個id塞啥
		"ENCYID": Connection.client_id,
		"HALFCUSTID": $("#password").val()
	}, function(data){
		if("Y" == data.PASSFLAG){
			call_hotai_api("LINELCS03_Q01", {  
				"DLRCD": "A",
				"BRNHCD": "52",
				"WORKNO": "07A0001"
			}, function(data){
				$("#dialog").dialog("close");
				var maintainLogs = data.LSFXINFO;
				var list = maintainLogs.map(function(item){
					return '<div class="list_element" onclick="javascript:moredetail(\'' + 
						item.DLRCD + '\',\'' + item.BRNHCD + '\',\'' + item.WORKNO + '\',\'' + 
						item.RTPTDT + '\',\'' + item.RTPTML + '\',\'' + item.TOTAMT + '\')">'+
					'	<div class="list-table">' +
					'		<div class="list-tr">' +
					'			<div class="list-cell">' + item.RTPTDT + '</div>' +
					'			<div class="list-cell">里程數：' + item.RTPTML + ' m</div>' +
					'			<div class="list-cell">' +
					'				<div style="float:right;font-size: 1.3em;">></div>' +
					'			</div>' +
					'		</div>' +
					'	</div>' +
					'</div>';
				}).join('');
	
				$('#maintain_logs').html(list);
				$('#maintain-page').toggle();
			});
		}else{
			alert("密碼錯誤" + (data.rtnMsg ? "," + data.rtnMsg : ""));
		}
	});
}