#!/usr/bin/env node_modules/coffee-script/bin/coffee

fs      = require('fs')
request = require('request')
program = require('commander')
async   = require('async')
_       = require('lodash')
exec    = require('child_process').exec
moment  = require('moment')
cheerio = require('cheerio')
clc     = require('cli-color')

program
  .version('0.0.1')
  .usage('-m [manga ex. bleach] -v [volume ex. 30] -e [episode ex. 268]')
  .option('-m, --manga <value>', 'Specify manga, view manga list on https://github.com/phatograph/mangafetcher#currently-supported-manga')
  .option('-v, --volume <n>', 'Specify volume')
  .option('-e, --episode <a>..<b>', 'Specify episode', (val) -> val.split('..').map(Number))
  .option('-p, --pages [items]', 'Specify pages (optional) e.g. -p 2,4,5', (val) -> val.split(','))
  .option('-l, --list', 'List mode')
  .parse(process.argv)

##############################################################################
# Manga Urls
##############################################################################

mangaUrls =
  'bleach'        : "http://mangafox.me/manga/bleach"
  'one-piece'     : "http://mangafox.me/manga/one_piece"
  'naruto'        : "http://mangafox.me/manga/naruto"
  'sk'            : "http://www.mangahere.com/manga/shaman_king"
  'sk-f'          : "http://www.mangahere.com/manga/shaman_king_flowers"
  'nisekoi'       : "http://www.mangahere.com/manga/nisekoi_komi_naoshi"
  'denpa-kyoushi' : "http://www.mangahere.com/manga/denpa_kyoushi"
  'trinity-seven' : "http://www.mangahere.com/manga/trinity_seven"
  'mkm'           : "http://www.mangahere.com/manga/minamoto_kun_monogatari"
  'to-love-ru-d'  : "http://www.mangahere.com/manga/to_love_ru_darkness"
  'shokugeki'     : "http://www.mangahere.com/manga/shokugeki_no_soma"
  'shinmai'       : "http://www.mangahere.com/manga/shinmai_maou_no_keiyakusha"
  'masamune'      : "http://www.mangahere.com/manga/masamune_kun_no_revenge"
  'eyeshield21'   : "http://www.mangahere.com/manga/eyeshield_21"

##############################################################################
# Image Downloading Functions
##############################################################################

padding = (value, length) ->
  String(('0' for i in [0...length]).join('') + value).slice(length * -1)

createFolder = (folderPath) ->
  for path in folderPath.split '/'
    initPath = "#{initPath || '.'}/#{path}"
    fs.mkdirSync(initPath) unless fs.existsSync(initPath)

mangaDownload = (vol, ep) ->
  fraction = if ep.match /\./ then _.last(ep.split('.')) else false
  ep       = ep.split('.')[0]

  uri = switch program.manga
    when 'bleach', 'one-piece', 'naruto'
         "#{mangaUrls[program.manga]}/v#{if vol is 'TBD' then 'TBD' else padding(vol, 2)}/c#{padding(ep, 3)}/"
    when 'sk'
         "#{mangaUrls[program.manga]}/v#{vol}/c#{ep}"
    else "#{mangaUrls[program.manga]}/c#{padding(ep, 3)}#{if fraction then '.' + fraction else ''}"

  console.log uri

  request uri: uri, (err, res, body) ->
    if err or res.statusCode isnt 200
      console.log clc.red "Oops, something went wrong #{'(Error: ' + res.statusCode + ')'if res}"
      return false

    $ = cheerio.load(body)
    pageAmount = switch program.manga
      when 'bleach', 'one-piece', 'naruto'
            $('form#top_bar select.m option').length
      else  $('section.readpage_top select.wid60 option').length
    pages = program.pages || [0..pageAmount]
    uri = uri.slice(0, -1) if uri.match /\/$/  # Remove trailing `/`

    console.log clc.green "Downloading up to #{pages.length} page(s)"
    for i in _.clone pages
      do (i) ->
        request uri: "#{uri}/#{i}.html", followRedirect: false, (err, res, body) ->
          $$        = cheerio.load(body)
          paddedVol = padding(vol, 3)
          paddedEp  = padding(ep, 3)
          paddedEp += ".#{fraction}" if fraction

          if err or res.statusCode isnt 200
            pages.splice(pages.indexOf(i), 1)
          else
            img = $$('img#image')

            unless img.length
              pages.splice(pages.indexOf(i), 1)
            else
              imgUri = switch program.manga
                when 'bleach', 'one-piece', 'naruto'
                     img.attr('onerror').match(/http.+jpg/)[0]  # New manga seems to fallback to another CDN
                else img.attr('src')

              request.head uri: imgUri, followRedirect: false, (err2, res2, body2) ->
                if res2.headers['content-type'] is 'image/jpeg'
                  folderPath = "manga/#{program.manga}/#{program.manga}-#{paddedVol}-#{paddedEp}"
                  fileName   = "#{padding(i, 2)}.jpg"
                  filePath   = "./#{folderPath}/#{fileName}"

                  createFolder(folderPath)
                  request(uri: imgUri, timeout: 120 * 1000)
                    .pipe fs.createWriteStream(filePath)
                    .on 'finish', ->
                      pages.splice(pages.indexOf(i), 1)
                      exec("touch -t #{moment().format('YYYYMMDD')}#{padding(i, 4)} #{filePath}")  # Since iOS seems to sort images by created date, this should do the trick

                      if pages.length is 0
                        console.log clc.green "\nDone ##{ep}!"
                      else if pages.length > 3
                        if (pageAmount - pages.length) % 5
                          process.stdout.write "."
                        else
                          process.stdout.write "#{pageAmount - pages.length}"
                      else
                        process.stdout.write "\nRemaining (##{ep}): #{pages.join(', ')}" if pages.length

mangaList = ->
  for name, url of mangaUrls
    do (name, url) ->
      request uri: "#{mangaUrls[name]}/", followRedirect: false, (err, res, body) ->
        $          = cheerio.load(body)
        label      = switch name
                      when 'bleach', 'one-piece', 'naruto'
                           $('a.tips').first().text().trim()
                      else $('div.detail_list span.left a.color_0077').first().text().trim()
        labelNum   = ~~(_.last(label.split(' ')))
        folderPath = "./manga/#{name}"

        if fs.existsSync(folderPath)
          fs.readdir folderPath, (e, folders) ->
            _.remove(folders, (x) -> x is '.DS_Store')
            latestFolder = ~~(_.last(_.last(folders).split('-'))) if folders.length
            color = if latestFolder is labelNum then clc.green else clc.red

            console.log "#{label} [#{clc.yellow name}] (local: #{color(latestFolder || '-')}/#{labelNum})"

##############################################################################
# App Kickoff!
##############################################################################

if program.list then mangaList()
else if program.manga and program.episode
  episodes =  [program.episode[0]..(program.episode[1] || program.episode[0])]
  for ep in episodes
    mangaDownload(program.volume || 0, ep.toString())
else
  console.log 'Error: please specify manga, volume and episode'
