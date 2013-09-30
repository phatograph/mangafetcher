#!/usr/bin/env coffee

fs = require('fs')
request = require('request')
program = require('commander')
async = require('async')
_ = require('lodash')

program
  .version('0.0.1')
  .usage('-v [volume ex. 30] -e [episode ex. 268]')
  .option('-v, --volume <n>', 'Specify volume')
  .option('-e, --episode <n>', 'Specify episode')
  .parse(process.argv)

bleachUri = (option = {},vol, ep, folderName, pageNum = "01", doublePage = false) ->
  option = _.extend({
    folderName: ''
    pageNum: 1
    doublePage: 0
    fileType: 'jpg'
    ext1: ''
    ext2: ''
    volExt: 0
  }, option)

  pageNum = if option.pageNum < 10 then "0#{option.pageNum}" else option.pageNum
  if option.doublePage
    pageDual = option.pageNum + 1;
    pageDual = "0#{pageDual}" if pageDual < 10
    pageNum += "_#{pageDual}"

  "http://z.mfcdn.net/store/manga/9/#{option.vol}-#{~~option.ep}.#{option.volExt}/compressed/#{option.folderName}#{option.ext1}#{option.ext2}#{pageNum}.#{option.fileType}"

downloadImage = (uriFunc, option) ->
  fileName = if option.pageNum < 10 then "0#{option.pageNum}.jpg" else "#{option.pageNum}.jpg"
  uri = option.uri

  async.timesSeries 2, (n, next) ->
    request.head uri[n], (err, res, body) ->
      if res.headers['content-type'] is 'image/jpeg'
        request(uri: uri[n], timeout: 120 * 1000).pipe(fs.createWriteStream("manga/bleach/#{option.vol}-#{option.ep}/#{fileName}"))
        next "Downloading: #{fileName}#{ if n == 1 then ' (dual)' else '' }"
      else
        if n == 0  # first time failing, perform for a dual page
          next null, true
        else  # not found
          next "Not found: #{fileName}"
  , (err) -> console.log err

downloadEpPerform = (uriFunc, option) ->
  unless fs.existsSync("manga/bleach/#{option.vol}-#{option.ep}")
    fs.mkdirSync("manga/bleach/#{option.vol}-#{option.ep}")

  console.log uriFunc(option)

  for i in [0..30]
    do (i) ->
      option.pageNum = i
      option.uri = []
      option.doublePage = false
      option.uri.push(uriFunc(option))
      option.doublePage = true
      option.uri.push(uriFunc(option))

      downloadImage(uriFunc, option)

downloadEp = (vol, ep) ->
  perform = (name, callback, option) ->
    request.head bleachUri(option), (err, res, body) ->
      if res.headers['content-type'] is 'image/jpeg'
        downloadEpPerform(bleachUri, option)
        callback name

  async.parallel [
    (callback) ->
      perform 0, callback, vol: vol, ep: ep, folderName: 'M7_Bleach_Ch', ext1: ep, ext2: '_'
    (callback) ->
      perform 1, callback, vol: vol, ep: ep, folderName: 'M7_Bleach_ch', ext1: ep, ext2: '_'
    (callback) ->
      perform 2, callback, vol: vol, ep: ep, folderName: 'm7_bleach_ch', ext1: ep, ext2: '_'
    (callback) ->
      perform 3, callback, vol: vol, ep: ep, folderName: 'page'
    (callback) ->
      perform 4, callback, vol: vol, ep: ep, folderName: 'Bleach_', ext1: ep, ext2: '_'
    (callback) ->
      perform 5, callback, vol: vol, ep: ep
    (callback) ->
      perform 6, callback, vol: vol, ep: ep, folderName: "bleach_#{ep}_ms.bleach_#{ep}_"
    (callback) ->
      perform 7, callback, vol: vol, ep: ep, folderName: "bleach_#{ep - 20}_ms.bleach_#{ep}_pg"
    (callback) ->
      perform 8, callback, vol: vol, ep: ep, folderName: "Bleach_#{ep}_pg"
    (callback) ->
      perform 9, callback, vol: vol, ep: ep, folderName: "ATBleach_#{ep}_0"
    (callback) ->
      perform 10, callback, vol: vol, ep: ep, folderName: "Bleach_#{ep}_MS.Bleach_#{ep}_pg"
    (callback) ->
      perform 11, callback, vol: vol, ep: ep, folderName: "#{ep}.atbleach_#{ep}_0"
    (callback) ->
      perform 12, callback, vol: vol, ep: ep, folderName: "atbleach_#{ep}_0"
    (callback) ->
      perform 13, callback, vol: vol, ep: ep, folderName: "bleach_#{ep}_fh."
    (callback) ->
      perform 14, callback, vol: vol, ep: ep, folderName: "bleach_#{ep}_binktopia."
    (callback) ->
      perform 15, callback, vol: vol, ep: ep, folderName: "bleach_#{ep}_"
    (callback) ->
      offset = ep * 10 - ~~ep * 10
      perform 16, callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_binktopia.", volExt: offset
    (callback) ->
      offset = ep * 10 - ~~ep * 10
      perform 17, callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_", volExt: offset
    (callback) ->
      offset = ep * 10 - ~~ep * 10
      perform 18, callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_binktopia_v1.", volExt: offset
  ],
  (err) -> console.log "Using option #{err}\n"

if program.volume and program.episode
  downloadEp(program.volume, program.episode)
else
  console.log 'Error: please specify both volume and episode'
