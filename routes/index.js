var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

router.get('/cs_customer', function(req, res, next) {
  res.render('cs_customer');
});

router.get('/cs_manager', function(req, res, next) {
  res.render('cs_manager');
});

router.get('/cs_manager_list', function(req, res, next) {
  res.render('cs_manager_list');
});

module.exports = router;
