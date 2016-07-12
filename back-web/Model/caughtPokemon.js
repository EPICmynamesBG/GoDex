module.exports = function(mongoose) {
  var Schema = mongoose.Schema;

  var CaughtPokemonSchema = new Schema({
    pid: Number,
    geo_lat: Number,
    geo_long: Number,
    time: Number
  });

  return mongoose.model('caughtPokemon', CaughtPokemonSchema);
}
