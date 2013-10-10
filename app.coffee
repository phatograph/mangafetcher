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

##############################################################################
# URI Functions
##############################################################################

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

  ep = String('000' + ~~option.ep).slice(-3)  # http://gugod.org/2007/09/padding-zero-in-javascript.html
  pageNum = String('00' + option.pageNum).slice(-2)
  if option.doublePage
    pageDual = option.pageNum + 1;
    pageDual = "0#{pageDual}" if pageDual < 10
    pageNum += "#{option.doublePageSep}#{pageDual}"

  "http://z.mhcdn.net/store/manga/6712/#{ep}.#{option.volExt}/compressed/#{option.folderName}#{pageNum}.#{option.fileType}"

##############################################################################
# Image Downloading Functions
##############################################################################

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
    option = _.extend({
      vol: vol
      ep: ep
    }, option)

    uriFunc = switch program.manga
      when 'bleach' then bleachUri
      when 'sk-f' then skfUri

    # console.log uriFunc(option)
    request.head uriFunc(option), (err, res, body) ->
      if res.headers['content-type'] is 'image/jpeg'
        callback uriFunc(option)
        downloadEpPerform(uriFunc, option)

  switch program.manga
    when 'bleach'
      async.parallel [
        (callback) -> offset = ep * 10 - ~~ep * 10; perform callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_binktopia.", volExt: offset
        (callback) -> offset = ep * 10 - ~~ep * 10; perform callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_", volExt: offset
        (callback) -> offset = ep * 10 - ~~ep * 10; perform callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_binktopia_v1.", volExt: offset
        (callback) -> offset = ep * 10 - ~~ep * 10; perform callback, vol: vol, ep: ep, folderName: "", volExt: offset
        (callback) -> offset = ep * 10 - ~~ep * 10; perform callback, vol: vol, ep: ep, folderName: "0", volExt: offset
        (callback) -> offset = ep * 10 - ~~ep * 10; perform callback, vol: vol, ep: ep, folderName: "bleach_#{109 - offset}_sleepyfans.", volExt: offset
        (callback) -> offset = ep * 10 - ~~ep * 10; perform callback, vol: vol, ep: ep, folderName: "bleach_#{~~ep}_sleepyfans.", volExt: offset
        (callback) -> perform callback
        (callback) -> perform callback, folderName: 'M7_Bleach_Ch', ext1: ep, ext2: '_'
        (callback) -> perform callback, folderName: 'M7_Bleach_ch', ext1: ep, ext2: '_'
        (callback) -> perform callback, folderName: 'm7_bleach_ch', ext1: ep, ext2: '_'
        (callback) -> perform callback, folderName: 'page'
        (callback) -> perform callback, folderName: 'Bleach_', ext1: ep, ext2: '_'
        (callback) -> perform callback, folderName: "bleach_#{ep}_ms.bleach_#{ep}_"
        (callback) -> perform callback, folderName: "bleach_#{ep - 20}_ms.bleach_#{ep}_pg"
        (callback) -> perform callback, folderName: "Bleach_#{ep}_pg"
        (callback) -> perform callback, folderName: "ATBleach_#{ep}_0"
        (callback) -> perform callback, folderName: "Bleach_#{ep}_MS.Bleach_#{ep}_pg"
        (callback) -> perform callback, folderName: "#{ep}.atbleach_#{ep}_0"
        (callback) -> perform callback, folderName: "atbleach_#{ep}_0"
        (callback) -> perform callback, folderName: "bleach_#{ep}_fh."
        (callback) -> perform callback, folderName: "bleach_#{ep}_binktopia."
        (callback) -> perform callback, folderName: "bleach_#{ep}_"
        (callback) -> perform callback, folderName: "bleach_#{ep}_sleepyfans.0"
        (callback) -> perform callback, folderName: "bleach_#{ep}."
        (callback) -> perform callback, folderName: "ubleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "hbleach_#{ep}_by_sleepyfans."
        (callback) -> perform callback, folderName: "fbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "u"
        (callback) -> perform callback, folderName: "l"
        (callback) -> perform callback, folderName: "qbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "sbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "bbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "pbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "mbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "kbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "rbleach_#{ep}_"
        (callback) -> perform callback, folderName: "rbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "ebleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "nbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "b"
        (callback) -> perform callback, folderName: "cbleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "ibleach_#{ep}_sleepyfans."
        (callback) -> perform callback, folderName: "sbleach_#{ep}_us."
        (callback) -> perform callback, folderName: "q#{ep}_"
        (callback) -> perform callback, folderName: "pbleach#{ep}_"
        (callback) -> perform callback, folderName: "gbleach_#{ep}_ss."
        (callback) -> perform callback, folderName: "fbleach_#{ep}_ss."
        (callback) -> perform callback, folderName: "gbleach_#{ep}_sleepyfans."
      ],
      (err) -> console.log "Using option #{err}\n"

    when 'sk-f'
      async.parallel [
        (callback) -> perform callback, folderName: "bm_t_sk_flowers_chapter_01_pg"
        (callback) -> perform callback, folderName: "bm-t_shaman_king_flowers_chapter_011_pg0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "dm-t_shaman_king_flowers_chapter_001_pg0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "cm-t_shaman_king_flowers_chapter_003_pg0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "gm-t_shaman_king_flowers_chapter_010_pg0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "nm-t_shaman_king_flowers_chapter_012_pg0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "rm-t_shaman_king_flowers_chapter_016_pg0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "pm-t_shaman_king_fanbook_002_pg0", doublePageSep: '-0', volExt: '5', pageNum: 0
        (callback) -> perform callback, folderName: "r0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "b0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "j0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "n0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "h0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "v0", doublePageSep: '-0'
        # (callback) -> perform callback, folderName: "u0", doublePageSep: '-0'
        (callback) -> perform callback, folderName: "f0", doublePageSep: '-0'
      ],
      (err) -> console.log "Using option #{err}\n"

    else console.log 'Error: manga not found!'

##############################################################################
# App Kickoff!
##############################################################################

if program.manga and program.volume and program.episode
  downloadEp(program.volume, program.episode)
else
  console.log 'Error: please specify manga, volume and episode'
