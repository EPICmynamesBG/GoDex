var express = require('express');
var router = express.Router();

/* GET users listing. */
router.get('/', function(req, res, next) {
  res.render('policy', { title: 'GoDex --- Developer\'s Page' });
});

module.exports = router;
