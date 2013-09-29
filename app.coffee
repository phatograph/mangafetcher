#!/usr/bin/env coffee

fs = require('fs')
request = require('request')
program = require('commander')
async = require('async')

program
  .version('0.0.1')
  .usage('-v [volume ex. 30] -e [episode ex. 268]')
  .option('-v, --volume <n>', 'Specify volume', parseInt)
  .option('-e, --episode <e>', 'Specify episode', parseInt)
  .parse(process.argv)

bleachUri = (vol, ep, folderName, pageNum = "01", doublePage = false) ->
  pageNum = "#{pageNum}_#{pageNum + 1}" if doublePage
  "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/#{folderName}#{ep}_#{pageNum}.jpg"

bleachUri2 = (vol, ep, folderName, pageNum = "01", doublePage = false) ->
  pageNum = "#{pageNum}_#{pageNum + 1}" if doublePage
  "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/#{folderName}#{pageNum}.jpg"

downloadImage = (uriFunc, vol, ep, folderName, pageNum, fileName) ->
  async.timesSeries 2, (n, next) ->
    uri = uriFunc(vol, ep, folderName, pageNum, n)  # if n is 1, would perform for a dual page
    request.head uri, (err, res, body) ->
      if res.headers['content-type'] is 'image/jpeg'
        request(uri: uri, timeout: 120 * 1000).pipe(fs.createWriteStream("manga/bleach/#{vol}-#{ep}/#{fileName}"))
        next "Downloading: #{fileName}#{ if n == 1 then ' (dual)' else '' }"
      else
        if n == 0  # first time failing, perform for a dual page
          next null, true
        else  # not found
          next "Not found: #{fileName}"
  , (err) -> console.log err

downloadEpPerform = (uriFunc, vol, ep, folderName) ->
  unless fs.existsSync("manga/bleach/#{vol}-#{ep}")
    fs.mkdirSync("manga/bleach/#{vol}-#{ep}")

  console.log uriFunc(vol, ep, folderName)

  for i in [0..30]
    do (i) ->
      i = "0#{i}" if i < 10
      downloadImage(uriFunc, vol, ep, folderName, i, "#{i}.jpg")

downloadEp = (vol, ep) ->
  async.parallel [
    (callback) ->
      request.head bleachUri(vol, ep, 'M7_Bleach_Ch'), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, vol, ep, 'M7_Bleach_Ch')
          callback 'a'
    (callback) ->
      request.head bleachUri(vol, ep, 'M7_Bleach_ch'), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, vol, ep, 'M7_Bleach_ch')
          callback 'b'
    (callback) ->
      request.head bleachUri(vol, ep, 'm7_bleach_ch'), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, vol, ep, 'm7_bleach_ch')
          callback 'c'
    (callback) ->
      request.head bleachUri2(vol, ep, 'page'), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri2, vol, ep, 'm7_bleach_ch')
          callback 'd'
    (callback) ->
      request.head bleachUri(vol, ep, 'Bleach_'), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, vol, ep, 'Bleach_')
          callback 'e'
    (callback) ->
      request.head bleachUri2(vol, ep, ''), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri2, vol, ep, '')
          callback 'f'
  ],
  (err) -> console.log "Using option #{err[0]}\n"

if program.volume and program.episode
  downloadEp(program.volume, program.episode)
else
  console.log 'Error: please specify both volume and episode'
