module.exports = function(app, express) {
  var router = express.Router();
  var http = require('http');
  var mongoose = require('mongoose');
  mongoose.connect('mongodb://172.31.59.160:27017/');

  router.use(function(req, res, next) {
    console.log("Middleware Firing");
    next();
  });

  router.get('/', function(req, res) {
    res.json({ message: 'Testing API!'});
  });

  router.route('/AllPokemon')
    //GETS all pokemon supported
    .get(function(req, res) {
      res.json(
        [
          { id: 1,
            name: 'bulbasaur',
            image: 'http://pokeapi.co/media/sprites/pokemon/1.png'
          },
          { id: 2,
            name: 'test',
            image: 'http://pokeapi.co/media/sprites/pokemon/2.png'
          }
      ]);
    });

  router.route('/CaughtPokemon')
    //GETS all pokemon caught
    .get(function(req, res) {
      res.json({
        id: '234234234',
        pokemon_id: '1',
        geo_lat: '23423.0103',
        geo_long: '12809.2098',
        time: Date.now()
      });
    })
    //POSTS a pokemon to the caught list
    .post(function(req, res) {

    });

  router.route('/CaughtPokemon/:pokemon_id')
    //GETS all the pokemon with an id
    .get(function(req, res) {

    });

  var port = process.env.PORT | 8080;

  app.use('/api', router);
  var server = http.createServer(app);
  server.listen(port);
  console.log("Cool Stuff Here: " + port);
}
