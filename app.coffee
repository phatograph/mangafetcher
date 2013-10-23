#!/usr/bin/env coffee

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
  .option('-m, --manga <value>', 'Specify manga, currently available are [bleach, sk, sk-f, nisekoi, denpa-kyoushi, trinity-seven]')
  .option('-v, --volume <n>', 'Specify volume')
  .option('-e, --episode <n>', 'Specify episode')
  .option('-p, --pages [items]', 'Specify pages (optional) e.g. -p 2,4,5', (val) -> val.split(','))
  .option('-l, --list', 'List mode')
  .parse(process.argv)

##############################################################################
# Manga Urls
##############################################################################

mangaUrls =
  'bleach':        "http://mangafox.me/manga/bleach"
  'sk':            "http://www.mangahere.com/manga/shaman_king"
  'sk-f':          "http://www.mangahere.com/manga/shaman_king_flowers"
  'nisekoi':       "http://www.mangahere.com/manga/nisekoi_komi_naoshi"
  'denpa-kyoushi': "http://www.mangahere.com/manga/denpa_kyoushi"
  'trinity-seven': "http://www.mangahere.com/manga/trinity_seven"

##############################################################################
# Image Downloading Functions
##############################################################################

padding = (value, length) ->
  String(('0' for i in [0...length]).join('') + value).slice(length * -1)

mangaDownload = (vol, ep) ->
  now = new Date()
  uri = switch program.manga
    when 'bleach' then "#{mangaUrls[program.manga]}/v#{padding(vol, 2)}/c#{padding(ep, 3)}/"
    when 'sk'     then "#{mangaUrls[program.manga]}/v#{vol}/c#{ep}"
    else               "#{mangaUrls[program.manga]}/c#{padding(ep, 3)}"

  request uri: uri, followRedirect: false, (err, res, body) ->
    if err or res.statusCode isnt 200
      console.log clc.red "Oops, something went wrong  #{'(Error: ' + res.statusCode + ')'if res}"
      return false

    $ = cheerio.load(body)
    pageAmount = switch program.manga
      when 'bleach' then $('form#top_bar select.m option').length
      else               $('section.readpage_top select.wid60 option').length
    pages = program.pages || [0..pageAmount]
    uri = uri.slice(0, -1) if uri.match /\/$/  # Remove trailing `/`

    console.log clc.green "Downloading up to #{pages.length} page(s)"
    for i in _.clone pages
      do (i) ->
        request uri: "#{uri}/#{i}.html", followRedirect: false, (err, res, body) ->
          paddedVol = padding(vol, 3)
          paddedEp = padding(ep, 3)

          if err or res.statusCode isnt 200
            pages.splice(pages.indexOf(i), 1)
          else
            pattern = switch program.manga
              when 'bleach'        then      /http:\/\/z.mfcdn.net\/store\/manga\/9\/.+\/compressed\/.+\.jpg"/
              when 'sk'            then     /http:\/\/z.mhcdn.net\/store\/manga\/65\/.+\/compressed\/.+\.jpg/
              when 'sk-f'          then   /http:\/\/z.mhcdn.net\/store\/manga\/6712\/.+\/compressed\/.+\.jpg/
              when 'nisekoi'       then   /http:\/\/z.mhcdn.net\/store\/manga\/8945\/.+\/compressed\/.+\.jpg/
              when 'denpa-kyoushi' then  /http:\/\/z.mhcdn.net\/store\/manga\/10266\/.+\/compressed\/.+\.jpg/
              when 'trinity-seven' then   /http:\/\/z.mhcdn.net\/store\/manga\/9272\/.+\/compressed\/.+\.jpg/

            unless img = body.match pattern
              pages.splice(pages.indexOf(i), 1)
            else
              imgUri = img[0]
              imgUri = imgUri.slice(0, -1) if imgUri.match /"$/  # Remove trailing `"`

              request.head imgUri, (err2, res2, body2) ->
                folderPath = "manga/#{program.manga}/#{program.manga}-#{paddedVol}-#{paddedEp}"
                for path in folderPath.split '/'
                  initPath = "#{initPath || '.'}/#{path}"
                  fs.mkdirSync(initPath) unless fs.existsSync(initPath)

                if res2.headers['content-type'] is 'image/jpeg'
                  nowOffset = new Date(now.setMinutes(i))
                  fileName = "#{padding(i, 2)}.jpg"
                  filePath = "./#{folderPath}/#{fileName}"

                  request(uri: imgUri, timeout: 120 * 1000)
                    .pipe fs.createWriteStream(filePath)
                    .on 'finish', ->
                      pages.splice(pages.indexOf(i), 1)
                      exec("touch -t #{moment().format('YYYYMMDD')}#{padding(i, 4)} #{filePath}")  # Since iOS seems to sort images by created date, this should do the trick

                      if pages.length == 0
                        console.log clc.green "\nDone!"
                      else if pages.length > 3
                        if (pageAmount - pages.length) % 5
                          process.stdout.write "."
                        else
                          process.stdout.write "#{pageAmount - pages.length}"
                      else
                        process.stdout.write "\nRemaining: #{pages.join(', ')}" if pages.length

mangaList = ->
  for name, url of mangaUrls
    do (name, url) ->
      request uri: "#{mangaUrls[name]}/", followRedirect: false, (err, res, body) ->
        $          = cheerio.load(body)
        label      = switch name
                      when 'bleach' then $('a.tips').first().text().trim()
                      else $('div.detail_list span.left a.color_0077').first().text().trim()
        labelNum   = ~~(_.last(label.split(' ')))
        folderPath = "./manga/#{name}"

        if fs.existsSync(folderPath)
          fs.readdir folderPath, (e, folders) ->
            _.remove(folders, (x) -> x is '.DS_Store')
            latestFolder = ~~(_.last(_.last(folders).split('-'))) if folders.length
            color = if latestFolder is labelNum then clc.green else clc.red

            console.log "#{label} (local: #{color(latestFolder || '-')}/#{labelNum})"

##############################################################################
# App Kickoff!
##############################################################################

if program.list then mangaList()
else if program.manga and program.episode
  mangaDownload(program.volume || 0, program.episode)
else
  console.log 'Error: please specify manga, volume and episode'
