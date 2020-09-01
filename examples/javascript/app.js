
var express = require('express');
var cors = require('cors');
var bodyParser = require('body-parser');
var query = require('./query');
var invoke = require('./invoke');

var app = express();

app.use(cors());
app.use(bodyParser.json());

app.get('/', function (req, res) {
  query.main().then(resp => {
    res.send(resp.toString());
  });
});

app.post('/', function (req, res) {
    invoke.create(req.body.code, req.body.brand, req.body.model, req.body.color, req.body.owner).then(resp => {
        res.send(resp);
    });
  });

app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});