module.exports = function(mongoose) {
  var Schema = mongoose.Schema;

  var FeedbackSchema = new Schema({
    feedback: String
  });

  return mongoose.model('feedback', FeedbackSchema);
}
