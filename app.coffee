fs = require('fs')
request = require('request')

downloadImage = (uri, fileName, ep) ->
  request.head uri, (err, res, body) ->
    if res.headers['content-type'] is 'image/jpeg'
      request(uri: uri, timeout: 120 * 1000).pipe(fs.createWriteStream("#{ep}/#{fileName}"))
    else
      console.log "Not found: #{fileName}"

downloadEpPerform = (vol, ep, folderName) ->
  for i in [0..30]
    do (i) ->
      i = "0#{i}" if i < 10
      downloadImage("http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/#{folderName}#{ep}_#{i}.jpg", "#{i}.jpg", ep)

downloadEp = (vol, ep) ->
  unless fs.existsSync(ep.toString())
    fs.mkdirSync(ep.toString())

  uri = "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/M7_Bleach_Ch#{ep}_01.jpg"
  request.head uri, (err, res, body) ->
    if res.headers['content-type'] is 'image/jpeg'
      console.log "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/M7_Bleach_Ch#{ep}_01.jpg"
      downloadEpPerform(vol, ep, 'M7_Bleach_Ch')
    else
      uri = "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/M7_Bleach_ch#{ep}_01.jpg"
      request.head uri, (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          console.log "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/M7_Bleach_ch#{ep}_01.jpg"
          downloadEpPerform(vol, ep, 'M7_Bleach_ch')
        else
          uri = "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/m7_bleach_ch#{ep}_01.jpg"
          request.head uri, (err, res, body) ->
            if res.headers['content-type'] is 'image/jpeg'
              console.log "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/m7_bleach_ch#{ep}_01.jpg"
              downloadEpPerform(vol, ep, 'm7_bleach_ch')
            else
              console.log 'Not found!'

downloadEp(30, 264)
