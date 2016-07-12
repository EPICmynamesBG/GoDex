module.exports = function(mongoose) {
  var Schema = mongoose.Schema;

  var PokemonSchema = new Schema({
    pid: Number,
    name: String,
    image: String
  });

  return mongoose.model('pokemon', PokemonSchema);
}
