#!/usr/bin/env coffee

fs = require('fs')
request = require('request')
program = require('commander')
async = require('async')
_ = require('lodash')

program
  .version('0.0.1')
  .usage('-v [volume ex. 30] -e [episode ex. 268]')
  .option('-v, --volume <n>', 'Specify volume', parseInt)
  .option('-e, --episode <e>', 'Specify episode', parseInt)
  .parse(process.argv)

bleachUri = (option = {},vol, ep, folderName, pageNum = "01", doublePage = false) ->
  option = _.extend({
    folderName: ''
    pageNum: 1
    doublePage: 0
    fileType: 'jpg'
    ext1: ''
    ext2: ''
  }, option)

  pageNum = if option.pageNum < 10 then "0#{option.pageNum}" else option.pageNum
  if option.doublePage
    pageDual = option.pageNum + 1;
    pageDual = "0#{pageDual}" if pageDual < 10
    pageNum += "_#{pageDual}"

  "http://z.mfcdn.net/store/manga/9/#{option.vol}-#{option.ep}.0/compressed/#{option.folderName}#{option.ext1}#{option.ext2}#{pageNum}.#{option.fileType}"

bleachUri2 = (vol, ep, folderName, pageNum = "01", doublePage = false) ->
  pageNum = "#{pageNum}_#{pageNum + 1}" if doublePage
  "http://z.mfcdn.net/store/manga/9/#{vol}-#{ep}.0/compressed/#{folderName}#{pageNum}.jpg"

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
  async.parallel [
    (callback) ->
      option = vol: vol, ep: ep, folderName: 'M7_Bleach_Ch', ext1: ep, ext2: '_'
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'a'
    (callback) ->
      option = vol: vol, ep: ep, folderName: 'M7_Bleach_ch', ext1: ep, ext2: '_'
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'b'
    (callback) ->
      option = vol: vol, ep: ep, folderName: 'm7_bleach_ch', ext1: ep, ext2: '_'
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'c'
    (callback) ->
      option = vol: vol, ep: ep, folderName: 'page'
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'd'
    (callback) ->
      option = vol: vol, ep: ep, folderName: 'Bleach_', ext1: ep, ext2: '_'
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'e'
    (callback) ->
      option = vol: vol, ep: ep
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'f'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "bleach_#{ep}_ms.bleach_#{ep}_"
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'g'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "bleach_#{ep - 20}_ms.bleach_#{ep}_pg"
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'h'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "Bleach_#{ep}_pg"
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'i'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "ATBleach_#{ep}_0"
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'j'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "Bleach_#{ep}_MS.Bleach_#{ep}_pg"
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'k'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "#{ep}.atbleach_#{ep}_0"
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'l'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "atbleach_#{ep}_0"
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'm'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "bleach_#{ep}_fh."
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'n'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "bleach_#{ep}_binktopia."
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'o'
    (callback) ->
      option = vol: vol, ep: ep, folderName: "bleach_#{ep}_"
      request.head bleachUri(option), (err, res, body) ->
        if res.headers['content-type'] is 'image/jpeg'
          downloadEpPerform(bleachUri, option)
          callback 'p'
  ],
  (err) -> console.log "Using option #{err[0]}\n"

if program.volume and program.episode
  downloadEp(program.volume, program.episode)
else
  console.log 'Error: please specify both volume and episode'
