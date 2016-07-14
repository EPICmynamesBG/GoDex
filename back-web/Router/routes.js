module.exports = function(app, express) {
  var router = express.Router();
  var http = require('http');
  var mongoose = require('mongoose');
  var Pokemon = require('../Model/pokemon.js')(mongoose);
  var CaughtPokemon = require('../Model/caughtPokemon')(mongoose);

  mongoose.connect('mongodb://127.0.0.1/godex');

  router.use(function(req, res, next) {
    next();
  });

  router.route('/AllPokemon')
    //GETS all pokemon from the supported pokemon store
    .get(function(req, res) {
      Pokemon.find(function(err, pokemon) {
        if (err) {
          res.send(err);
        } else {
          res.json(pokemon);
        }
      });
    });

  router.route('/AllPokemon/Enabled')
    //GETS all enabled pokemon from supported pokemon store
    .get(function(req, res) {
      Pokemon.find( {enabled: true}, function(err, pokemon) {
        if (err) {
          res.send(err);
        } else {
          res.json(pokemon);
        }
      });
    });

  router.route('/AllPokemon/Disabled')
    //GETS all disabled pokemon from supported pokemon store
    .get(function(req, res) {
      Pokemon.find( {enabled: false}, function(err, pokemon) {
        if (err) {
          res.send(err);
        } else {
          res.json(pokemon);
        }
      });
    });

  router.route('/AllPokemon/FindById/:pokemon_id')
    //GETS pokemon based on id, from all pokemon supported store
    //Used to ensure capture post contains a supported pokemon
    //Sends empty json object, if pokemon is not found
    //If found, json object containing pokemon id is sent
    .get(function(req, res) {
        console.log(req.params.pokemon_id);
        Pokemon.find({'pid': req.params.pokemon_id}, function(err, foundPokemon) {
          if (err) {
            res.send(err);
          } else {
            res.json(foundPokemon);
          }
        });
    });

  router.route('/AllPokemon/:pokemon_name')
    // ** Use this to get pokemon json object based on the name **
    //GETS pokemon based on name, from all pokemon supported store
    //Used to ensure capture post contains a supported pokemon
    //Sends empty json object, if pokemon is not found
    //If found, json object containing pokemon id is sent
    .get(function(req, res) {
        console.log(req.params.pokemon_name);
        Pokemon.find({'name': req.params.pokemon_name}, function(err, foundPokemon) {
          if (err) {
            res.send(err);
          } else {
            res.json(foundPokemon);
          }
        });
    });

  router.route('/CaughtPokemon')
    //GETS all pokemon caught
    .get(function(req, res) {
      CaughtPokemon.find(function(err, pokemon) {
        if (err) {
          res.send(err);
        } else {
          res.json(pokemon);
        }
      });
    });

  router.route('/CaughtPokemon/:pokemon_id')
    //GETS all the pokemon caught with an id
    .get(function(req, res) {
      CaughtPokemon.find({'pid': req.params.pokemon_id}, function(err, foundPokemon) {
        if (err) {
          res.send(err);
        } else {
          res.json(foundPokemon);
        }
      });
    });

  router.route('/CaughtPokemon/:uuid/:pokemon_id/:geo_lat/:geo_long')
    //POST a captured pokemon
    .post(function(req, res) {
      Pokemon.findOne({'pid': req.params.pokemon_id}, function(err, foundPokemon) {
        if (err) {
          res.send(err);
        }

        if (foundPokemon!= null) {
          var caughtPokemon = new CaughtPokemon();
          caughtPokemon.uuid = req.params.uuid;
          caughtPokemon.pid = req.params.pokemon_id;
          caughtPokemon.geo_lat = req.params.geo_lat;
          caughtPokemon.geo_long = req.params.geo_long;
          caughtPokemon.time = Date.now();

          //Creating array for JSON to stay consitent with other return values
          var caughtPokemonArr = [];
          caughtPokemon.save(function(err, poke) {
            if (err) {
              return console.log(err);
            } else {
              caughtPokemonArr.push(poke);
              res.json(caughtPokemonArr);
            }
          });
        } else {
          res.json({error: "Pokemon ID does not exist"})
        }
      });
    });

  var port = 8080;
  app.use('/api', router);
  var server = http.createServer(app);
  server.listen(port);
}
