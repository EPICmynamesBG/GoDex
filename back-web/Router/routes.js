module.exports = function(app, express) {
  var router = express.Router();

  router.get('/', function(req, res) {
    res.json({ message: 'Testing API!'});
  });

  var port = process.env.PORT | 8080;

  app.use('/api', router);
  app.listen(port);
  console.log("Cool Stuff Here: " + port);
}
