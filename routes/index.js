var express = require('express');
var router = express.Router();
var common = require('../service/common');

router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

router.get('/cs_customer_dialog', function(req, res, next) {
  res.render('cs_customer_dialog');
});
router.get('/cs_customer_list', function(req, res, next) {
  res.render('cs_customer_list');
});
router.get('/cust.do', function(req, res, next) {
  res.render('cs_customer');
});

router.get('/cs_manager_dialog', function(req, res, next) {
  res.render('cs_manager_dialog');
});

router.get('/cs_manager_list', function(req, res, next) {
  res.render('cs_manager_list');
});
router.get('/serv.do', function(req, res, next) {
  
  let func_list =["金牌話術","訊息推播","照片","相機","撥打","出價","車主資料","常用訊息"];
  
  let list_data = require('../service/specialist.json', 'utf-8');
  res.render('cs_manager',{
    list_data: list_data,
	func_list: func_list
  });
  
});

router.get('/api/json/sl', common.getSl);
router.get('/api/json/dl', common.getDl);
router.get('/api/json/tl', common.getTl);

module.exports = router;
