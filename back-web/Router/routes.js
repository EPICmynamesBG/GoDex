module.exports = function(app, express) {
  var router = express.Router();
  var http = require('http');
  var mongoose = require('mongoose');
  var Pokemon = require('../Model/pokemon.js')(mongoose);
  var CaughtPokemon = require('../Model/caughtPokemon.js')(mongoose);
  var Feedback = require('../Model/feedback.js')(mongoose);
  var geolib = require('geolib');

  mongoose.connect('mongodb://52.7.61.252:27017/godex');

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
      CaughtPokemon.find({}, {'time': 1, 'geo_long': 1, 'geo_lat': 1, 'pid': 1}, function(err, pokemon) {
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
      CaughtPokemon.find({'pid': req.params.pokemon_id}, {'time': 1, 'geo_long': 1, 'geo_lat': 1, 'pid': 1}, function(err, foundPokemon) {
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
      if (-180 > req.params.geo_lat ||
        req.params.geo_lat > 180 ||
        -180 > req.params.geo_long ||
        req.params.geo_long > 180) {
        res.json([{error: "Invalid Geolocation Values"}]);
        return;
      }
      //Creating array for JSON to stay consitent with other return values
      var caughtPokemonArr = [];
      Pokemon.findOne({'pid': req.params.pokemon_id}, function(err, foundPokemon) {
        if (err) {
          res.send(err);
        }

        CaughtPokemon.findOne({'uuid': req.params.uuid }, {}, {sort: {'time': -1}}, function(err, foundPost) {
          var timeLimit = 30000; //30 seconds, until the user can make another post
          var timeStamp = Date.now();

          if (foundPost != null) {
            //Distance is represented in meters
            var distance = geolib.getDistance(
              {'latitude': foundPost.geo_lat, 'longitude': foundPost.geo_long},
              {'latitude': req.params.geo_lat, 'longitude': req.params.geo_long});
            var distanceLimit = 63.6; //Equivalent to 1 acre

            if (foundPost.pid == req.params.pokemon_id && timeStamp - foundPost.time <= timeLimit && distance <= distanceLimit) {
              res.json([{error: "Repeat sighting. Please try again later!"}]);
              return;
            }
          }

          if (foundPokemon!= null) {
            var caughtPokemon = new CaughtPokemon();
            caughtPokemon.uuid = req.params.uuid;
            caughtPokemon.pid = req.params.pokemon_id;
            caughtPokemon.geo_lat = req.params.geo_lat;
            caughtPokemon.geo_long = req.params.geo_long;
            caughtPokemon.time = timeStamp;

            caughtPokemon.save(function(err, poke) {
              if (err) {
                return console.log(err);
              } else {
                caughtPokemonArr.push(poke);
                res.json(caughtPokemonArr);
              }
            });
          } else {
            res.json([{error: "Pokemon ID does not exist"}]);
          }
        });
      });
    });

  router.route('/Feedback')
    .post(function(req, res) {
      var newFeedback = new Feedback();
      newFeedback.feedback = req.body.feedback;
      console.log(newFeedback.feedback);
      newFeedback.save(function(err, newFeedbackCreated) {
        if (err) {
          return console.log(err);
        } else {
          console.log(newFeedbackCreated)
          res.json([newFeedbackCreated]);
        }
      });
    });

  router.route('/Feedback/All')
    .get(function(req, res) {
      Feedback.find({}, function(err, allFeedback) {
        if (err) {
          res.send(err);
        } else {
          res.json(allFeedback);
        }
      })
    });

  var port = 8080;
  app.use('/api', router);
  var server = http.createServer(app);
  server.listen(port);
}
