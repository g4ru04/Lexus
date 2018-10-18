var express = require('express');
var router = express.Router();
var formidable = require("formidable");
var uuid = require('uuid');

router.post('/', function (req, res){
    var form = new formidable.IncomingForm();
	let uuid_file_name = uuid.v1();
	
    form.parse(req);

    form.on('fileBegin', function (name, file){
		console.log(file);
		if(file.type=="image/jpeg"){
			uuid_file_name += ".jpg";
		}else if(file.type=="image/png"){
			uuid_file_name += ".png";
		}
        file.path = './public/images/uploaded/' + uuid_file_name;
    });

    form.on('file', function (name, file){
        console.log('Uploaded ' + file.name + ' to ' + uuid_file_name );
		res.send({
			'status':'success',
			'url':'http://' + req.headers.host + '/images/uploaded/' + uuid_file_name
		});
    });
});

module.exports = router;
