var express = require('express');
var app = express();
var bodyParser = require('body-parser');
require("./Router/routes.js")(app, express)

app.use(bodyParser.urlencoded({ extended: true}));
app.use(bodyParser.json());
