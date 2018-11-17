var express = require('express');
var router = express.Router();
var common = require('../service/common');
var ht_api = require('../service/ht_api.js');
var sp = require('../service/sp');
const settings = require('../configs.js');

router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

router.post('/api', async function(req, res, next) {
	res.send(await ht_api.callApi(req.body));
});

router.get('/cust.do', function(req, res, next) {
	res.send(`<html>
		<head>
			<title>頁面讀取中</title>
			<script src="/javascripts/common.js"></script>
		</head>
		<body>
			<script>
				post('/cust.do', {c: getUrlParameter('c'),s: getUrlParameter('s')});
			</script>
		</body>
	</html>`)
});

router.post('/cust.do', function(req, res, next) {
  console.log(req.body);
  res.render('cs_customer',{
	  socket_server_ip: settings.socket_server.ip,
	  c: req.body.c,
	  s: req.body.s
  });
});

router.get('/serv.do', function(req, res, next) {
	res.render('cs_manager',{
		socket_server_ip:settings.socket_server.ip
	});
});

router.get('/demo.do', function(req, res, next) {
  res.send(`<html>
		<head>
			<title>Frames</title>
		</head>
		<frameset cols="*,500px,500px,500px">
			<frame>
			<frame name="upper_right" src="/cust.do?c=QzAwMDM=&s=U0UwMDAx">
			<frame name="upper_right" src="/cust.do?c=QzAwMDE=&s=U0UwMDAx">
			<frame name="lower_right" src="/serv.do">
		</frameset> 
	</html>`);
});

// router.post('/line_send_message', function(req, res){
// 	sp.line_send_message(req, res);
// });
router.post('/upload_image', function(req, res){
	sp.upload_image(req, res);
});

router.get('/api/json/sl', common.getSl);
router.get('/api/json/dl', common.getDl);
router.get('/api/json/tl', common.getTl);

module.exports = router;
