module.exports = function(mongoose) {
  var Schema = mongoose.Schema;

  var CaughtPokemonSchema = new Schema({
    uuid: String,
    pid: Number,
    geo_lat: Number,
    geo_long: Number,
    time: Number
  });

  return mongoose.model('caughtPokemon', CaughtPokemonSchema);
}
