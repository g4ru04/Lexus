//Only for cs_customer

$( function() {
	
	set_dialog();
	
	$(".btn-search").click(function(){
		send_text_msg();
	});
	
	$("input.input.msg").keypress(function(e) {
		if(e.which == 13) {
		   send_text_msg();
		}
	});
	$(".btn-picture").click(function(){
		$("#upload_picture").trigger("click"); 
	});
	
} );

function save_picture(){
	
	let file_val = $('#upload_picture').val();
	let validExts = [".png",".jpg",".jpeg",".gif",".bmp"];
	let file_ext = file_val.substring(file_val.lastIndexOf('.'))
	if (validExts.indexOf(file_ext.toLowerCase()) < 0) {
		$('#upload_picture').val('');
		alert("只接受此類圖片檔案：" + validExts.join(", "));
		return ;
	}
	
	var data = new FormData();
    $.each($('#upload_picture')[0].files, function(i, file) {
        data.append('file-'+i, file);
    });
	$.ajax({
		url: '/upload',
		type: 'POST',
		data: data,
		cache: false,
        contentType: false,
        processData: false,
        method: 'POST',
		success: function(data){
			if(data.status=="success"){
				send_image_msg(data.url);
			}else{
				alert("檔案上傳失敗");
			}
		},
		error: function(xhr, status, error) {
			console.log(xhr);
			console.log(status);
			console.log(error);
		}
	});
}