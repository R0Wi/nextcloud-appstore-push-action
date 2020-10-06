/*
*   This is a mockserver for 
*       - Nextclouds appstore API
*       - Github releases tarball download API
*/

var express = require('express');
var http = require('http');
var bodyParser = require('body-parser');

var app = express();
app.use(bodyParser.text({
  type: function(req) {
    return 'text';
  }
}));

/** Github releases tarball API */
app.use('/github/test_app_artifact.tar.gz', express.static(__dirname + '/test_app_artifact.tar.gz'));

/** Nextcloud appstore API */
app.post('/api/v1/apps/releases', function (req, res) {
  console.log(req.body);
  res = res.status(200);
  if (req.get('Content-Type')) {
    console.log("Content-Type: " + req.get('Content-Type'));
    res = res.type(req.get('Content-Type'));
  }
  res.send(req.body);
});

app.get('/stop', function (req, res) {
    res = res.status(200);
    res.send('OK');
    setTimeout(() => { process.exit(0); }, 1000);
});

const server = http.createServer(app);
server.listen(7000);