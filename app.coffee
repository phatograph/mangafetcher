#!/usr/bin/env coffee

fs = require('fs')
request = require('request')
program = require('commander')
async = require('async')
_ = require('lodash')

program
  .version('0.0.1')
  .usage('-m [manga ex. bleach] -v [volume ex. 30] -e [episode ex. 268]')
  .option('-m, --manga <value>', 'Specify manga, currently available are [bleach, sk-f]')
  .option('-v, --volume <n>', 'Specify volume')
  .option('-e, --episode <n>', 'Specify episode')
  .option('-n, --amount [n]', 'Specify amount (optional)')
  .parse(process.argv)

bleachUri = (option = {}) ->
  option = _.extend({
    folderName: ''
    pageNum: 1
    doublePage: 0
    fileType: 'jpg'
    ext1: ''
    ext2: ''
    volExt: 0
  }, option)

  pageNum = String('00' + option.pageNum).slice(-2)
  if option.doublePage
    pageDual = option.pageNum + 1;
    pageDual = "0#{pageDual}" if pageDual < 10
    pageNum += "_#{pageDual}"

  "http://z.mfcdn.net/store/manga/9/#{option.vol}-#{~~option.ep}.#{option.volExt}/compressed/#{option.folderName}#{option.ext1}#{option.ext2}#{pageNum}.#{option.fileType}"

skfUri = (option = {}) ->
  option = _.extend({
    folderName: ''
    pageNum: 1
    doublePage: 0
    doublePageSep: '_'
    fileType: 'jpg'
    ext1: ''
    ext2: ''
    volExt: 0
  }, option)

  ep = String('000' + option.ep).slice(-3)  # http://gugod.org/2007/09/padding-zero-in-javascript.html
  pageNum = String('00' + option.pageNum).slice(-2)
  if option.doublePage
    pageDual = option.pageNum + 1;
    pageDual = "0#{pageDual}" if pageDual < 10
    pageNum += "#{option.doublePageSep}#{pageDual}"

  "http://z.mhcdn.net/store/manga/6712/#{ep}.0/compressed/#{option.folderName}#{pageNum}.#{option.fileType}"

downloadImage = (option) ->
  fileName = if option.pageNum < 10 then "0#{option.pageNum}.jpg" else "#{option.pageNum}.jpg"
  uri = option.uri

  async.timesSeries 2, (n, next) ->
    request.head uri[n], (err, res, body) ->
      if res.headers['content-type'] is 'image/jpeg'
        request(uri: uri[n], timeout: 120 * 1000).pipe(fs.createWriteStream("manga/#{program.manga}/#{option.vol}-#{option.ep}/#{fileName}"))
        next "Downloading: #{fileName}#{ if n == 1 then ' (dual)' else '' }"
      else
        if n == 0  # first time failing, perform for a dual page
          next null, true
        else  # not found
          next "Not found: #{fileName}"
  , (err) -> console.log err

downloadEpPerform = (uriFunc, option) ->
  unless fs.existsSync("manga")
    fs.mkdirSync("manga")
  unless fs.existsSync("manga/#{program.manga}")
    fs.mkdirSync("manga/#{program.manga}")
  unless fs.existsSync("manga/#{program.manga}/#{option.vol}-#{option.ep}")
    fs.mkdirSync("manga/#{program.manga}/#{option.vol}-#{option.ep}")

  pageAmount = program.amount || switch program.manga
    when 'bleach' then 30
    when 'sk-f' then 50
    else 30

  for i in [0..pageAmount]
    do (i) ->
      option.pageNum = i
      option.uri = []
      option.doublePage = false
      option.uri.push(uriFunc(option))
      option.doublePage = true
      option.uri.push(uriFunc(option))

      downloadImage(option)

downloadEp = (vol, ep) ->
  perform = (callback, option) ->
    uriFunc = switch program.manga
      when 'bleach' then bleachUri
      when 'sk-f' then skfUri

    request.head uriFunc(option), (err, res, body) ->
      if res.headers['content-type'] is 'image/jpeg'
        callback uriFunc(option)
        downloadEpPerform(uriFunc, option)

  switch program.manga
    when 'bleach'
      async.parallel [
        (callback) -> perform callback, vol: vol, ep: ep, folderName: 'M7_Bleach_Ch', ext1: ep, ext2: '_'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: 'M7_Bleach_ch', ext1: ep, ext2: '_'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: 'm7_bleach_ch', ext1: ep, ext2: '_'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: 'page'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: 'Bleach_', ext1: ep, ext2: '_'
        (callback) -> perform callback, vol: vol, ep: ep
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bleach_#{ep}_ms.bleach_#{ep}_"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bleach_#{ep - 20}_ms.bleach_#{ep}_pg"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "Bleach_#{ep}_pg"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "ATBleach_#{ep}_0"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "Bleach_#{ep}_MS.Bleach_#{ep}_pg"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "#{ep}.atbleach_#{ep}_0"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "atbleach_#{ep}_0"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bleach_#{ep}_fh."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bleach_#{ep}_binktopia."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bleach_#{ep}_"
        (callback) ->
          offset = ep * 10 - ~~ep * 10
          perform callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_binktopia.", volExt: offset
        (callback) ->
          offset = ep * 10 - ~~ep * 10
          perform callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_", volExt: offset
        (callback) ->
          offset = ep * 10 - ~~ep * 10
          perform callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_binktopia_v1.", volExt: offset
        (callback) ->
          offset = ep * 10 - ~~ep * 10
          perform callback, vol: vol, ep: ep, folderName: "", volExt: offset
        (callback) ->
          offset = ep * 10 - ~~ep * 10
          perform callback, vol: vol, ep: ep, folderName: "0", volExt: offset
        (callback) ->
          offset = ep * 10 - ~~ep * 10
          perform callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_sleepyfans.", volExt: offset
        (callback) ->
          offset = ep * 10 - ~~ep * 10
          perform callback, vol: vol, ep: ep, folderName: "bleach_#{~~ep}_sleepyfans.", volExt: offset
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bleach_#{ep}_sleepyfans.0"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bleach_#{ep}."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "ubleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "hbleach_#{ep}_by_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "fbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "u"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "l"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "qbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "sbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "pbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "mbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "kbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "rbleach_#{ep}_"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "rbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "ebleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "nbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "b"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "cbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "ibleach_#{ep}_sleepyfans."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "sbleach_#{ep}_us."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "q#{ep}_"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "pbleach#{ep}_"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "gbleach_#{ep}_ss."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "fbleach_#{ep}_ss."
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "gbleach_#{ep}_sleepyfans."
      ],
      (err) -> console.log "Using option #{err}\n"

    when 'sk-f'
      async.parallel [
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bm_t_sk_flowers_chapter_01_pg"
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "dm-t_shaman_king_flowers_chapter_001_pg0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "cm-t_shaman_king_flowers_chapter_003_pg0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "gm-t_shaman_king_flowers_chapter_010_pg0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "bm-t_shaman_king_flowers_chapter_011_pg0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "nm-t_shaman_king_flowers_chapter_012_pg0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "rm-t_shaman_king_flowers_chapter_016_pg0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "r0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "b0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "j0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "n0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "h0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "v0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "u0", doublePageSep: '-0'
        (callback) -> perform callback, vol: vol, ep: ep, folderName: "f0", doublePageSep: '-0'
      ],
      (err) -> console.log "Using option #{err}\n"

    else console.log 'Error: manga not found!'

if program.manga and program.volume and program.episode
  downloadEp(program.volume, program.episode)
else
  console.log 'Error: please specify manga, volume and episode'
