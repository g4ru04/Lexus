var express = require('express');
var router = express.Router();
var common = require('../service/common');
const settings = require('../configs.js');

router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

router.get('/cust.do', function(req, res, next) {
  res.render('cs_customer',{
	  socket_server_ip:settings.socket_server.ip
  });
});

router.get('/serv.do', function(req, res, next) {
  if(req.query.s==null){
	  res.render('cs_manager_login');
  }else{
    let func_list =["金牌話術","_訊息推播","照片","相機","撥打電話","_預約","_車主資料"/*,"常用訊息"*/];
  
    let list_data = require('../service/specialist.json', 'utf-8');
    res.render('cs_manager',{
      list_data: list_data,
	  func_list: func_list,
	  socket_server_ip:settings.socket_server.ip
    });
  }
});

/* for 金融案例 */
router.get('/serv_fin.do', function(req, res, next) {
  res.render('cs_manager_fin');
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



router.get('/api/json/sl', common.getSl);
router.get('/api/json/dl', common.getDl);
router.get('/api/json/tl', common.getTl);

module.exports = router;
