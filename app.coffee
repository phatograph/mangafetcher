#!/usr/bin/env coffee

fs = require('fs')
request = require('request')
program = require('commander')

program
  .version('0.0.1')
  .usage('-v [volume ex. 30] -e [episode ex. 268]')
  .option('-v, --volume <n>', 'Specify volume', parseInt)
  .option('-e, --episode <e>', 'Specify episode', parseInt)
  .parse(process.argv)

bleachUri = (vol, ep, folderName, pageNum = "01", doublePage = false) ->
  pageNum = "#{pageNum}_#{pageNum + 1}" if doublePage
  "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/#{folderName}#{ep}_#{pageNum}.jpg"

downloadImage = (vol, ep, folderName, pageNum, fileName) ->
  uri = bleachUri(vol, ep, folderName, pageNum)
  request.head uri, (err, res, body) ->
    if res.headers['content-type'] is 'image/jpeg'
      console.log "Downloaded: #{fileName}"
      request(uri: uri, timeout: 120 * 1000).pipe(fs.createWriteStream("#{ep}/#{fileName}"))
    else
      uri = bleachUri(vol, ep, folderName, pageNum, true)
      request.head uri, (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          console.log "Downloaded: #{fileName} (Dual)"
          request(uri: uri, timeout: 120 * 1000).pipe(fs.createWriteStream("#{ep}/#{fileName}"))
        else
          console.log "Not found: #{fileName}"

downloadEpPerform = (vol, ep, folderName) ->
  console.log bleachUri(vol, ep, folderName)
  for i in [0..30]
    do (i) ->
      i = "0#{i}" if i < 10
      downloadImage(vol, ep, folderName, i, "#{i}.jpg")

downloadEp = (vol, ep) ->
  unless fs.existsSync(ep.toString())
    fs.mkdirSync(ep.toString())

  request.head bleachUri(vol, ep, 'M7_Bleach_Ch'), (err, res, body) ->
    if res.headers['content-type'] is 'image/jpeg'
      downloadEpPerform(vol, ep, 'M7_Bleach_Ch')
    else
      request.head bleachUri(vol, ep, 'M7_Bleach_ch'), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(vol, ep, 'M7_Bleach_ch')
        else
          request.head bleachUri(vol, ep, 'm7_bleach_ch'), (err, res, body) ->
            if res.headers['content-type'] is 'image/jpeg'
              downloadEpPerform(vol, ep, 'm7_bleach_ch')
            else
              console.log 'Not found!'

if program.volume and program.episode
  downloadEp(program.volume, program.episode)
else
  console.log 'Error: please specify both volume and episode'
