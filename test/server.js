/*
*   This is a mockserver for 
*       - Nextclouds appstore API
*       - Github releases tarball download API
*/

const express = require('express');
const http = require('http');
const bodyParser = require('body-parser');
const fs = require('fs');

var app = express();
app.use(bodyParser.text({
  type: function(req) {
    return 'text';
  }
}));

/** Github releases tarball API */
app.use('/github/test_app_artifact.tar.gz', express.static(__dirname + '/test_app_artifact.tar.gz'));

/** Nextcloud appstore API */
app.post('/api/v1/apps/releases/ok', function (req, res) {
  var text = req.body + "\n" + JSON.stringify(req.headers);
  fs.writeFileSync('server_output.txt', text);
  if (req.get('Content-Type')) {
    res = res.type(req.get('Content-Type'));
  }
  res.status(200).send('');
});
app.post('/api/v1/apps/releases/badrequest', function (req, res) {
  if (req.get('Content-Type')) {
    res = res.type(req.get('Content-Type'));
  }
  res.status(400).send('{ "message": "error" }');
});

/** Stops the webserver after testing */
app.get('/stop', function (req, res) {
    res = res.status(200);
    res.send('OK');
    setTimeout(() => { process.exit(0); }, 1000);
});

const server = http.createServer(app);
server.listen(7000);