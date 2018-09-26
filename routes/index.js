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
  res.render('cs_manager');
});

router.get('/api/json/sl', common.getSl);
router.get('/api/json/dl', common.getDl);
router.get('/api/json/tl', common.getTl);

module.exports = router;
