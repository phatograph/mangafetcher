fs = require('fs')
request = require('request')

download = (uri, filename) ->
  request.head uri, (err, res, body) ->
    console.log('content-type:', res.headers['content-type']);
    console.log('content-length:', res.headers['content-length']);

    request(uri).pipe(fs.createWriteStream("256/#{filename}"))

download('http://z.mfcdn.net/store/manga/9/29-256.0/compressed/M7_Bleach_Ch256_01.jpg', 'google.png');
