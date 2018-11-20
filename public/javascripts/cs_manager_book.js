function initBook(){
	$("#btn-book").click(function(){
		//已有預約保修 flag
		var booked = false;

		if($('#book-menu').attr("style")!="display: none;"){
			$('#book-menu').attr("style", "display: none;");
			return;
		}

		call_hotai_api("LINELCS02_Q03",{  
			"LICSNO": Connection.client_info.vehicle_number
		},function(data){
			if(data.BOOKDATA.length>0){
				booked=true;
				alert("已有預約保修");
			}else{
				$('#cust-name').val(Connection.client_info.name);
				$('#cust-phone').val(Connection.client_info.PHONE);

				$('#service-factory').unbind('change');
				$('#service-factory').on('change', function(){
					var target = $('#service-factory').val().split('-');
					call_hotai_api('LINELCS02_Q02', {  
						"DLRCD": target[0] || Connection.service_info.DLRCD,
						"BRNHCD": target[1] || Connection.service_info.BRNHCD,
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