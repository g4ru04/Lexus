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
	$('.search_box_container > input').keyup(function(e){
		var input = $('.search_box_container > input').val();
		$('.cs_manager_list_container > .list_element').attr("style", "display: none;")
		if(input){
			var target = Connection.conversation_list.forEach(function(item){
				//console.log(item.conversation_title.includes(input), item.customer_nickname.includes(input))
				if(item.conversation_title.includes(input) || item.customer_nickname.includes(input))
					$('.cs_manager_list_container > .list_element[customer_id="' + item.customer_id + '"]').attr("style", "display: block;")
			});

			// if(target){
			// 	$('.cs_manager_list_container > .list_element[customer_id="' + target.customer_id + '"]').attr("style", "display: block;")
			// }
		}else{
			$('.cs_manager_list_container > .list_element').attr("style", "display: block;")
		}
	});
});

function to_login(){
	
	call_hotai_api("USER_LOGIN",{
		"USERID": $("#username").val(),
		"PWD": $("#password").val()
	},function(logindata){
		
		let login_info = logindata;
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
			// let manager_data = {
			// 	USERID: login_info.USERID,
			// 	ECHOTITLECD: login_info.ECHOTITLECD,
			// 	USERNM: login_info.USERNM,
			// 	PICURL: "https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png",
			// 	PHONE: null,
			// 	PERSONAL_DATA:login_info
			// };
			login_info.PICURL = "https://customer-service-xiang.herokuapp.com/images/Lexus_icon.png";
			login_info.PHONE = null;
			
			let responsibility_data = responsibility_info.USERINFO.map(function(item){
				return {
					USERID: item.USERID,
					ENCYID: item.ENCYID,
					NICKNAME: item.NICKNAME,
					CARNM: item.CARNM,
					LICSNO: item.LICSNO,
					PICURL: item.PICURL,
					MOBILE: item.MOBILE,
					FENDAT: item.FENDAT,
					UENDAT: item.UENDAT,
					BRTHDT: item.BRTHDT,
					FFLAG: item.FFLAG,
					UFLAG :item.UFLAG,
					BIRFLAG: item.BIRFLAG
				};
			});
			
			set_manager_socket(service_id,login_info,responsibility_data,logindata);
		});
	});
	
}


//設定 Socket 
function set_manager_socket( service_id, manager_data, responsibility_data,logindata){
	
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
		
		console.log('init')
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
				let target = Connection.conversation_list.find(function(item){
					return item.customer_id == Connection.client_info.id;
				});
				Connection.client_info = JSON.parse(conversation_data.customer_data);
				Connection.client_info.detail = target.detail;
				Connection.client_info.notify = {
					birth_need_notify: target.birth_need_notify || "Y",
					birth_notify: target.birth_notify || "Y",
					fend_need_notify: target.fend_need_notify || "Y",
					fend_notify: target.fend_notify || "Y",
					uend_need_notify: target.uend_need_notify || "Y",
					uend_notify: target.uend_notify || "Y"
				}
				//todo 太醜了
				Connection.service_info = JSON.parse(conversation_data.manager_data);
				Connection.service_info.BRNHCD = logindata.BRNHCD;
				Connection.service_info.COMPID = logindata.COMPID;
				Connection.service_info.COMPSIMPNM = logindata.COMPSIMPNM;
				Connection.service_info.DEPTSIMPNM = logindata.DEPTSIMPNM;
				Connection.service_info.DLRCD = logindata.DLRCD;
				Connection.service_info.ECHOTITLECD = logindata.ECHOTITLECD;
				Connection.service_info.FRAN = logindata.FRAN;

				$('#btn-call').attr('onclick','location.href="tel:'+Connection.client_info.PHONE+'";')
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
			var notify = Connection.client_info.notify;
			if((notify.birth_need_notify=="Y" && notify.birth_notify=="N") || 
			    (notify.fend_need_notify=="Y" && notify.fend_notify=="N")){
				$('#btn-custinfo')[0].style.backgroundColor = 'red';
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
				Connection.conversation_list = data[0];
				update_conversatoin_list(data[0]);
			},100);
		});

		Connection.socket.on('normal talk trick', function (data) {
			//["普通話術1", "普通話術2", "生日快樂1", "生日快樂2", "續保話術1", "該續保了2", "其他1", "其他話術"]
			Connection.normal_talk_trick = data;
			var birth = '<h3>生日祝賀1</h3><input type="button" id="normal-tricks-2" onclick="select_trick(event)" class="trick-content" value="' + data[2] + '">'+
					'<input type="button" onclick="edit_normal_trick(\'normal-tricks-2\',event)" value="編輯">'+
					'<h3>生日祝賀2</h3><input type="button" id="normal-tricks-3" onclick="select_trick(event)" class="trick-content" value="' + data[3] + '">'+
					'<input type="button" onclick="edit_normal_trick(\'normal-tricks-3\',event)" value="編輯">',
				fend = '<h3>續保話術1</h3><input type="button" id="normal-tricks-4" onclick="select_trick(event)" class="trick-content" value="' + data[4] + '">'+
					'<input type="button" onclick="edit_normal_trick(\'normal-tricks-4\',event)" value="編輯">'+
					'<h3>續保話術2</h3><input type="button" id="normal-tricks-5" onclick="select_trick(event)" class="trick-content" value="' + data[5] + '">'+
					'<input type="button" onclick="edit_normal_trick(\'normal-tricks-5\',event)" value="編輯">',
				other = '<h3>其他話術1</h3><input type="button" id="normal-tricks-6" onclick="select_trick(event)" class="trick-content" value="' + data[6] + '">'+
					'<input type="button" onclick="edit_normal_trick(\'normal-tricks-6\',event)" value="編輯">'+
					'<h3>其他話術2</h3><input type="button" id="normal-tricks-7" onclick="select_trick(event)" class="trick-content" value="' + data[7] + '">'+
					'<input type="button" onclick="edit_normal_trick(\'normal-tricks-7\',event)" value="編輯">';
			$('#tab-birth').html(birth);
			$('#tab-fend').html(fend);
			$('#tab-other').html(other);
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
		console.log(message)
		if(message.ans_ID){
			$("#talk_tricks_editor").attr("ans_ID",message.ans_ID);
		}
		if(message.talk_tricks){
			talk_tricks_setting(message.talk_tricks);
			$("#talk_tricks_container").addClass("enable"); 
		}
		if(!message.broadcast){
			$("#console").append(produce_dialog_element(message));
			$("#console").scrollTop($('#console')[0].scrollHeight);
		}
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
		item.detail = item.detail || {};

		let detail = item.detail=={} ? "" : 
			(item.detail.BIRFLAG == "Y" || item.detail.FFLAG == "Y") ?
				"<div class='note' title=''>"
					+"<div class='tooltip'>"
					+(item.detail.BIRFLAG == "Y"?"生日 ":"")
					+(item.detail.FFLAG == "Y"?"強制險 ":"")
						+"<span class='tooltiptext'>"
						+"</span>"
					+"</div>"
				+"</div>": "";
		
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
				+'			<div class="name" customer_id="' + item.customer_id+ '" onclick="edit_nickname(event)">'
				+					item.customer_nickname
				+'			</div>'
				+'			<input type="text" customer_id="' + item.customer_id+ '" value="' + item.customer_nickname + '" style="display:none;">'
				+'			<input type="button" customer_id="' + item.customer_id+ '" value="確認" style="display:none;" onclick="apply_edit_nickname(event)">'
				+'			<div class="msg">'
				+					item.last_message
				+'			</div>'
				+'		</div>'
				+			"<div class='timestamp'>"+displayChatTime(item.last_talk_time)+"&nbsp;</div>"
				+			(item.manager_unread?"<div class='unread'>"+item.manager_unread+"</div>":"")
				+			detail
				+'	</div>';
		return div_html;
	},"");
	
	$(".cs_manager_list_container").html(div_html);

	if((notify.birth_need_notify=="N" || notify.birth_notify=="Y") && 
		(notify.fend_need_notify=="N" || notify.fend_notify=="Y")){
		$('#btn-custinfo')[0].style.backgroundColor = '#ef3';
	}
}

function apply_edit_nickname(event){
    targetevent = event
	var target = event.srcElement.getAttribute('customer_id');

	Connection.socket.emit("edit customer name",{
		customer_id: target,
		manager_id: Connection.service_id,
		nickname: $('input[type="text"][customer_id="'+target+'"]').val()
	})

	$('input[customer_id="'+target+'"]').attr('style','display:none;');
	$('div.name[customer_id="'+target+'"]').attr('style','');
}
function edit_nickname(event){
    targetevent = event
	var target = event.srcElement.getAttribute('customer_id');
	$('div.name[customer_id="'+target+'"]').attr('style','display:none;');
	$('input[customer_id="'+target+'"]').attr('style','');
}


//一般話術
function tricks(type){
	type = type || "other";

	// Declare all variables
    var i, tabcontent, tablinks;

    // Get all elements with class="tabcontent" and hide them
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }

    // Get all elements with class="tablinks" and remove the class "active"
    tablinks = document.getElementsByClassName("tablinks");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
    }

    // Show the current tab, and add an "active" class to the button that opened the tab
    document.getElementById('tab-'+ type).style.display = "block";
    $('#Tab-'+ type).addClass('active')
}

function select_trick(event){
	$('.input.msg').val(event.target.value);
	$('#normal_talk_tricks').toggle();
}

//金牌話術
function talk_tricks_setting(data){
	
	let edit_div = "<div class='talk_tricks_edit'></div>";
	let talk_tricks_str = data.map(function(item){
		return "<div class='talk_trick'><a>"+item+"</a></div>";
	}).join("");
	
	$("#talk_tricks_container").html(edit_div + talk_tricks_str);
	
}

//功能選單
function menu_setting(){

	//預約流程
	initBook();
	$('#btn-custinfo').click(function(){
		call_hotai_api("LINELCS01_Q01",{
			"ENCYID": Connection.client_id
		},function(data){
			var data = data.USERDATA[0];
			$('#custinfo_name').html(Connection.client_info.name);
			$('#custinfo_address').html(data.ADDR);
			$('#custinfo_carno').html(Connection.client_info.vehicle_number?Connection.client_info.vehicle_number:"");
			$('#custinfo_phone').html(data.MOBILE);
			$('#custinfo_hascars').html("取得失敗");
			$('#custinfo_uendat').html(data.UENDAT);
			$('#custifo_brkds').html(data.BRKDS);
			$('#custifo_rtptml').html(data.RTPTML);
			$('#custinfo_advise').html(data.NXRPMO);
			$('#custifo_rtptdt').html(data.RTPTDT);

			// button?
			// 在14天內且Flag==Y
			var hasbutton = (countBirhday(data.BIRTHDAY)<14 && "Y" == Connection.client_info.detail.BIRFLAG);
			$('#custinfo_birthday').html(data.BIRTHDAY+
				(hasbutton ? ('<button onclick="javascript:tricks(\'birth\');$(\'#normal_talk_tricks\').toggle();$(\'#cust-info\').toggle();Notify(\''+Connection.client_id+'\',\'birth\');">生日祝賀</button>'):''));

			hasbutton = moment(data.FENDAT.replace(/\//g,'')).diff(moment(new Date())) < 14 &&
					"Y" == Connection.client_info.detail.FFLAG;
			$('#custifo_fendat').html(data.FENDAT+
				(hasbutton ? ('<button onclick="javascript:tricks(\'fend\');$(\'#normal_talk_tricks\').toggle();$(\'#cust-info\').toggle();Notify(\''+Connection.client_id+'\',\'fend\');">續保提醒</button>'):''));
			$('#cust-info').toggle();
		});
	})
}

function countBirhday(birthday){
	var today = new Date();
	var b = moment(today)
	birthday = birthday.split("/");
	
	if(birthday.length==2){
		birthday = (birthday[0].length == 2 ? birthday[0] : "0" + birthday[0]) +
				(birthday[1].length == 2 ? birthday[1] : "0" + birthday[1]);
	}else if(birthday.length==3){
		birthday = (birthday[1].length == 2 ? birthday[1] : "0" + birthday[1]) +
				(birthday[2].length == 2 ? birthday[2] : "0" + birthday[2]);
	}else{
		return "";
	}

	var result1 = moment((today.getFullYear()+1)+birthday).diff(b, 'days');
	var result2 = moment((today.getFullYear())+birthday).diff(b, 'days')

	return result1 < 365 ? result1 : result2;
}

function edit_normal_trick(id,event){
	if($('#'+id).attr('type') == 'text'){
		var target = id.split('-');
		$('#'+id).attr('onclick','select_trick(event)').attr('type','button');
		event.srcElement.value = "編輯";
		Connection.normal_talk_trick[target[2]] = $('#'+id).val();
		Connection.update_talk_tricks('Normal', Connection.normal_talk_trick);

	}else{
		$('#'+id).attr('onclick','').attr('type','text');
		event.srcElement.value = "確認";
	}
}

function Notify(customer_id, target){
	Connection.socket.emit('update notify flag',{
		customer_id: customer_id,
		target: target,
		value: "Y"
	});
}