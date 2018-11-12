//need jquery && jquery-ui

$( function() {
	
	emotion_setting();
	menu_setting();
	
	$("#talk_tricks_container").delegate( ".talk_trick", "click", function() {
		$(".input").val($(this).text());
		$("#talk_tricks_container").toggleClass("enable"); 
	});
	$("#talk_tricks_container").delegate( ".talk_tricks_edit", "click", function() {
		let talk_trick_text = [];
		$(".talk_tricks_edit").parent().find(".talk_trick").each(function(i,item){
			talk_trick_text.push($(item).text());
		});
		
		let editor_str = talk_trick_text.map(function(item){
			return "<div>"+
				"<input type='text' value='"+item+"' />"+
				"&nbsp;<span class='del'>DELETE</span>"+
				"</div>"
		}).join("<br>");
		console.log(talk_trick_text);
		console.log(talk_trick_text);
		
		$("#talk_tricks_editor").html(editor_str+"<div class='new'>new</div>");
		$("#talk_tricks_editor").dialog( "open" );
		
		
		$(".input").val($(this).text());
		$("#talk_tricks_container").toggleClass("enable"); 
	});
	$("#talk_tricks_editor").delegate( ".del", "click", function() {
		$(this).parent().remove();
	});
	$("#talk_tricks_editor").delegate( ".new", "click", function() {
		$(this).before("<br>");
		$(this).before(
			"<div>"+
			"<input type='text' value='' />"+
			"&nbsp;<span class='del'>DELETE</span>"+
			"</div>"
		)
		
	});
	$("#talk_tricks_editor").dialog({
			title: "修改相應回答話術",
			draggable : true, resizable : false, autoOpen : false,
			height : "auto", width : "600", modal : true,
			buttons : [{
				text: "修改", 
				click: function() { 
					$(this).dialog("close");
					let ans_ID = $("#talk_tricks_editor").attr("ans_ID");
					let talk_tricks = [];
					$("#talk_tricks_editor").find("input").each(function(i,item){
						talk_tricks.push($(item).val());
					})

					Connection.update_talk_tricks(ans_ID,talk_tricks);
				}
			},{
				text: "取消", 
				click: function() { 
					$(this).dialog("close");
				}
			}]
		});
	
});

function to_login(){
	
	call_hotai_api("USER_LOGIN",{
		"USERID": $("#username").val(),
		"PWD": $("#password").val()
	},function(data){
		
		let login_info = data;
		call_hotai_api("LINE006_Q01",{
			DLRCD: login_info.DLRCD,
			BRNHCD: login_info.BRNHCD,
			USERID: login_info.USERID,
			ECHOTITLECD: login_info.ECHOTITLECD,
			FRAN: login_info.FRAN
		},function(data){
			let responsibility_info = data
			$(".login_panel").hide();
			$(".after_login").show();
			let service_id = $("#username").val();
			let manager_data = {
				USERID: login_info.USERID,
				ECHOTITLECD: login_info.ECHOTITLECD,
				USERNM: login_info.USERNM,
				PICURL: "https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png",
				PHONE: null,
				PERSONAL_DATA:login_info
			};
			let responsibility_data = responsibility_info.USERINFO.map(function(item){
				return {
					USERID: item.USERID,
					ENCYID: item.ENCYID,
					NICKNAME: item.NICKNAME,
					CARNM: item.CARNM,
					LICSNO: item.LICSNO,
					PICURL: item.PICURL,
					MOBILE: item.MOBILE,
					NOTIFY_DATA: [{
						"type":"FEN",
						"day":item.FENDAT,
						"notify":item.FFLAG=="Y"
					},{
						"type":"UEN",
						"day":item.UENDAT,
						"notify":item.UFLAG=="Y"
					},{
						"type":"BRTH",
						"day":item.BRTHDT,
						"notify":item.BIRFLAG=="Y"
					}]
				};
			});
			
			set_manager_socket(service_id,manager_data,responsibility_data);
		});
	});
	
}


//設定 Socket 
function set_manager_socket( service_id, manager_data, responsibility_data){
	
	Connection = {}
	
	Connection.init = function(){
		Connection.socket = io(socket_server_ip);
		
		Connection.end_point = "service" ;
		Connection.client_id  = "";
		Connection.service_id = service_id?service_id:UUID();
		Connection.client_info = {
			"id":"",
			"name":"",
			"avator":"/images/avator.png",
			"PHONE":""
		};;
		Connection.service_info = {
			"id":"",
			"name":"",
			"avator":"/images/avator.png",
			"PHONE":""
		};
		Connection.conn = false ;
		Connection.talks = [];
		Connection.talks_history_cursor = 0;
		
		Connection.set_listener();
		
		common_conn_setting(Connection);
		
		Connection.socket.emit("register service",{
			type : Connection.end_point,
			service_id : Connection.service_id,
			manager_data : manager_data,
			responsibility_data : responsibility_data
		});
	}
	
	Connection.set_listener = function(){
		Connection.socket.on('enter', function (data) {
			console.log('data',data)
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
			console.log(
				"對話對象所見頁面",window.location.origin + "/cust.do"
					+"?c="+b64EncodeUnicode(Connection.client_id)
					+"&s="+b64EncodeUnicode(Connection.service_id)
			)
			if(Connection.talks_history_cursor==0){
				Connection.socket.emit("get history",{});
			}
		});
	
		Connection.socket.on('leave', function () {
			console.log("change_talk_target",{
				"leave":Connection.client_id,
				"join":Connection.next_client_id
			});
			if(Connection.next_client_id){
				Connection.talks = [] ;
				Connection.talks_history_cursor = 0;
				Connection.socket.emit("enter", {
					type : Connection.end_point,
					client_id : Connection.next_client_id,
					service_id : Connection.service_id
				});
			}
			Connection.client_id = Connection.next_client_id;
			Connection.next_client_id = null;
		});
		
		Connection.socket.on('reconnect', function () {
			Connection.conn = true;
			my_console("重新連接");
			//$("#console").html('<div class="loading_div"><img src="/images/loading.gif" /></div>');
			Connection.socket.emit("enter",{
				type : Connection.end_point,
				client_id : Connection.client_id,
				service_id : Connection.service_id,
			});
			Connection.socket.emit("register service",{
				type : Connection.end_point,
				service_id : Connection.service_id,
				manager_data : manager_data,
				responsibility_data : responsibility_data
			});
		});
		
		Connection.socket.on('update conversation list', function (data) {
			console.log("receive conversation list",data)
			setTimeout(function(){
				update_conversatoin_list(data[0]);
			},100);
		});
	}
	
	Connection.change_customer = function(client_id){
		console.log(client_id);
		Connection.next_client_id = client_id;
		Connection.socket.emit('leave',{
			type : Connection.end_point,
			client_id : Connection.client_id,
			service_id : Connection.service_id
		});
	}
	
	Connection.reiceive_msg = function (message){
		
		if(message.ans_ID){
			$("#talk_tricks_editor").attr("ans_ID",message.ans_ID);
		}
		if(message.talk_tricks){
			talk_tricks_setting(message.talk_tricks);
			$("#talk_tricks_container").addClass("enable"); 
		}
		$("#console").append(produce_dialog_element(message));
		$("#console").scrollTop($('#console')[0].scrollHeight);
	}
	
	Connection.update_talk_tricks = function(ans_ID,talk_tricks){
		console.log("update talk trick");
		console.log(ans_ID);
		console.log(talk_tricks);
		Connection.socket.emit('update talk trick',{
			dialog_id : ans_ID,
			talk_tricks : talk_tricks
		});
	}
	
	Connection.init();
}

function update_conversatoin_list(conversatoin_data){
	console.log("draw_conversatoin_list");
	let div_html = conversatoin_data.reduce(function(div_html,item){
		let note = item.note &&  item.note.length>0
								?"<div class='note' title=''>"
									+"<div class='tooltip'>重要提醒"
										+"<span class='tooltiptext'>"
											+item.note.map(function(item){return item.msg;})+
										+"</span>"
									+"</div>"
								+"</div>"
								:"";
		
		div_html +=
				"<div class='list_element "+(Connection.client_id == item.customer_id?"active":"")+"'"
				+"		 customer_id='"+item.customer_id+"'>"
				+'		<div class="img" alt="">'
				+'			<img src="'+item.avator+'" alt="">'
				+'		</div>'
				+'		<div class="chat_body">'
				+'			<div class="title">'
				+					item.conversation_title
				+'			</div>'
				+'			<div class="name">'
				+					item.customer_nickname
				+'			</div>'
				+'			<div class="msg">'
				+					item.last_message
				+'			</div>'
				+'		</div>'
				+			"<div class='timestamp'>"+displayChatTime(item.last_talk_time)+"&nbsp;</div>"
				+			(item.manager_unread?"<div class='unread'>"+item.manager_unread+"</div>":"")
				+			note
				+'	</div>';
		return div_html;
	},"");
	
	$(".cs_manager_list_container").html(div_html);
	
}

//金牌話術
function talk_tricks_setting(data){
	
	let edit_div = "<div class='talk_tricks_edit'></div>";
	let talk_tricks_str = data.map(function(item){
		return "<div class='talk_trick'><a>"+item+"</a></div>";
	}).join("");
	
	$("#talk_tricks_container").html( edit_div + talk_tricks_str );
	
}

//功能選單
function menu_setting(){

	//預約流程
	initBook();

	$("#btn-booklog").click(function(){
		call_hotai_api("LINELCS02_Q03",{  
			"LICSNO": Connection.client_info.vehicle_number
		},function(data){
			if(data.BOOKDATA.length>0){
				//塞資料
				data = data.BOOKDATA[0];
				$('#booklog_carno').html(data.LICSNO);
				$('#booklog_factory').html(data.BRNHNM);
				$('#booklog_content').html(data.REFCDNM);
				$('#booklog_time').html(data.BKDT);
				$('#booklog_name').html(data.CONTPSN);
				$('#booklog_phone').html(data.CONTEL);
				$('#booklog_other').html(data.REMARK);
				var timezone = 
					data.CALLOUTSEC == "1" ? "08:30-12:00" :
					data.CALLOUTSEC == "2" ? "13:00-17:30" :
					data.CALLOUTSEC == "3" ? "18:00-19:30" :
					data.CALLOUTSEC == "4" ? "任何時段" :
					/* "5" or others */ "無須連絡電話"
				$('#booklog_timezone').html(timezone);

				//取消預約
				$('#cancel_reservation').unbind('click');
				$('#cancel_reservation').click(function(){
					call_hotai_api("LINELCS02_D01", {  
						"SKEY": data.SKEY,
						"LICSNO": data.LICSNO,
						"CRTPGID": "USP_LINELCS02_D01",
						"DLRCD": data.DLRCD,
						"BRNHCD": data.BRNHCD,
						"WORKNO": data.WORKNO
					}, function(d){
						// 已為您取消 yyyy/mm/dd hh:mm 於 XX廠 的 OO保養 預約"
						Connection.send_text("已為您取消 " + data.BKDT + ' ' + data.BKSSEC + 
						" 於 " + data.BRNHNM + " 的 " + data.REFCDNM + " 預約");
						$('#book-log').toggle();
					});
				});
				$('#book-log').toggle();
			}else{
				alert("沒有預約記錄");
			}
		});
	});
}

function initBook(){
	$("#btn-book").click(function(){
		//已有預約保修 flag
		var booked = false;

		call_hotai_api("LINELCS02_Q03",{  
			"LICSNO": Connection.client_info.vehicle_number
		},function(data){
			if(data.BOOKDATA.length>0){
				booked=true;
				alert("已有預約保修");
			}else{
				$('#cust-name').val(Connection.client_info.name);
				$('#cust-phone').val(Connection.client_info.PHONE);

				$('#service-factory').on('change', function(){
					call_hotai_api('LINELCS02_Q02', {  
						"DLRCD": Connection.service_info.DLRCD,
						"BRNHCD": Connection.service_info.BRNHCD,
						"USERID": Connection.service_id
					}, function(data){
						var date_time = {}; //Object.keys(a)
						data.AVITIME.forEach(function(item){
							if(date_time.hasOwnProperty(item.ORDERDT)){
								if(!date_time[item.ORDERDT].includes(item.TIME_SET)){
									date_time[item.ORDERDT].push(item.TIME_SET)
								}
							}else{
								date_time[item.ORDERDT] = [item.TIME_SET] 
							}
						});
						$('#service-date').html('');
						$('#service-date').append(Object.keys(date_time).map(function(item){
							return '<option '+ 'value="' + item +'">' + item + '</option>';
						}).join(''));

						$('#service-date').unbind('change');
						$('#service-date').on('change', function(){
							$('#service-time').html('');
							$('#service-time').append(date_time[$('#service-date').val()].map(function(item){
								return '<option '+ 'value="' + item +'">' + item + '</option>';
							}).join(''));
						});
						$('#service-date').trigger('change');
					})
				});

				call_hotai_api('LINELCS02_Q01', '{}', function(data){

					//地區綁服務廠 { area : [factories], }
					var area_factory = {};
					data.BRNHMF.forEach(function(item){
						if(area_factory.hasOwnProperty(item.ZIPNM)){
							if(!area_factory[item.ZIPNM].includes(item.DLRCD +'-'+ item.BRNHCD)){
								area_factory[item.ZIPNM].push(item.DLRCD +'-'+ item.BRNHCD)
							}
						}else{
							area_factory[item.ZIPNM] = [item.DLRCD +'-'+ item.BRNHCD] 
						}
					});
					//todo 選地區只跑出對應地區服務廠
					
					var selectList = data.BRNHMF.map(function(item){
						//地區
						if(Connection.service_info.BRNHCD == item.BRNHCD && Connection.service_info.DLRCD == item.DLRCD) {
							('option[text="' + item.ZIPNM + '"]').attr('selected','selected')
						}
						//服務廠
						return '<option '+
							(Connection.service_info.BRNHCD == item.BRNHCD && Connection.service_info.DLRCD == item.DLRCD ? 
								'selected="selected"' : '') +
							'value="' + item.DLRCD +'-'+ item.BRNHCD +'">' +
							item.BRNHNM + '</option>';
					}).join('');
					$('#service-factory').append(selectList);
					$('#service-factory').trigger('change');
				});
				$("#book-menu").toggle();
			}
		})
	});
	//$("#service-date").datepicker({ dateFormat: 'yy/mm/dd' });
	$('#book-submit').click(function(){
		call_hotai_api('LINELCS02_I01', {  
			"LICSNO": Connection.client_info.vehicle_number,
			"DLRCD": Connection.service_info.DLRCD,
			"BRNHCD": Connection.service_info.BRNHCD,

			"BKDT": $('#service-date').val().replace(/\//g,'-'),
			"BKSSEC": $('#service-time').val(),
			//固定寫1
			"OPTP": "1", 
			//hardcore now 里程數
			"RTPTML": "0",
			"CONTPSN": Connection.client_info.name,
			"CONTTEL": Connection.client_info.PHONE,
			"CALLOUTSEC": $('#cust-contacttime').val(),
			"REMARK": $('#service-memo').val(),
			"CRTPGID": "LINELCS02_I01",
			"GVTYPE": $('#cust-wait').val()
			}, function(data){
				var retText = 
					'為您預約維修: \n' +
					'日期:' + $("#service-date").val() + '\n' +
					'時段:' + $("#service-time").val() + '\n' +
					'服務廠:' + $("#service-factory").val();
				
				Connection.send_text(retText);
			});
		
		$("#book-menu").toggle();
	});
	$("#cust-wait-btn").click(function(){
		var custWait = $('#cust-wait').val();
		this.innerText = custWait=="A" ? 'Ｘ 完工通知':'Ｏ 在場等候';
		$('#cust-wait').val(custWait=="A"?"C":"A");
	});
}
