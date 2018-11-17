const settings = require('../configs.js');
const request = require('request-promise');
var FroalaEditor = require('wysiwyg-editor-node-sdk/lib/froalaEditor.js');
 module.exports = {
	// line_send_message: function(req, res){
    //     let options = {
    //         uri: settings.line.sendmessage,
    //         method: 'POST',
    //         formData: req.body
    //     };
    //      request
    //     .post(options)
    //     .then((body) => {
    //         let bodyJSON = JSON.parse(body);
    //         console.log("Success:", bodyJSON);
    //     })
    //     .catch((error) => {
    //         console.error('LINE ERROR:', error);
    //     });
	// },
	upload_image: function(req, res){
		// Store image.
		FroalaEditor.Image.upload(req, '../uploads/', function(err, data) {
			// Return data.
			if (err) {
				console.log("err", err);
				return res.send(JSON.stringify(err));
			}
			console.log("data", data);
			res.send(data);
		});
	}
} 