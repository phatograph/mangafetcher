fs = require('fs')
request = require('request')

download = (uri, filename) ->
  request.head uri, (err, res, body) ->
    console.log('content-type:', res.headers['content-type']);
    console.log('content-length:', res.headers['content-length']);

    request(uri).pipe(fs.createWriteStream(filename))

download('https://www.google.com/images/srpr/logo3w.png', 'google.png');
