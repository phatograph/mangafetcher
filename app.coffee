#!/usr/bin/env node_modules/coffee-script/bin/coffee

fs        = require('fs')
request   = require('request')
program   = require('commander')
async     = require('async')
_         = require('lodash')
exec      = require('child_process').exec
moment    = require('moment')
cheerio   = require('cheerio')
clc       = require('cli-color')
mangaUrls = require('./manga')

program
  .version('0.0.1')
  .usage('-m [manga ex. bleach] -v [volume ex. 30] -e [episode ex. 268]')
  .option('-m, --manga <value>', 'Specify manga, view manga list on https://github.com/phatograph/mangafetcher#currently-supported-manga')
  .option('-v, --volume <n>', 'Specify volume')
  .option('-e, --episode <a>..<b>', 'Specify episode', (val) -> val.split('..').map(Number))
  .option('-p, --pages [items]', 'Specify pages (optional) e.g. -p 2,4,5', (val) -> val.split(','))
  .option('-l, --list', 'List mode')
  .option('-x, --eplist', 'Episode List mode')
  .option('-r, --rerender <value>', 'Rerender mode (for mangahere)')
  .parse(process.argv)

##############################################################################
# Manga Urls
##############################################################################


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

  uri = switch mangaUrls[program.manga].format
        when 1 then "#{mangaUrls[program.manga].url}/v#{if vol is 'TBD' then 'TBD' else padding(vol, 2)}/c#{padding(ep, 3)}/"
        when 2 then "#{mangaUrls[program.manga].url}/v#{vol}/c#{ep}"
        when 3 then "#{mangaUrls[program.manga].url}/v#{padding(vol, 2)}/c#{padding(ep, 3)}#{if fraction then '.' + fraction else ''}"
        else        "#{mangaUrls[program.manga].url}/c#{padding(ep, 3)}#{if fraction then '.' + fraction else ''}"

  console.log uri

  request uri: uri, (err, res, body) ->
    if err or res.statusCode isnt 200
      console.log clc.red "Oops, something went wrong #{'(Error: ' + res.statusCode + ')'if res}"
      return false

    $ = cheerio.load(body)
    host = mangaUrls[program.manga].url.match(/http:\/\/[.\w\d]+\//) || []
    host = host[0]
    pageAmount = switch host
                 when 'http://mangafox.me/' then $('form#top_bar select.m option').length  # for mangafoxes
                 else                       $('section.readpage_top select.wid60 option').length
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
              imgUri = switch host
                       when 'http://mangafox.me/' then img.attr('onerror').match(/http.+jpg/)[0]  # New manga seems to fallback to another CDN
                       else                            img.attr('src')

              # Rerender mode for mangahere
              imgUri = switch program.rerender
                       when '0' then imgUri.replace(/.\.mhcdn\.net/, 'm.mhcdn.net')
                       when '1' then imgUri.replace(/.\.mhcdn\.net/, 's.mangahere.com')
                       else          imgUri

              request.head uri: imgUri, followRedirect: false, (err2, res2, body2) ->
                if res2.headers['content-type'] is 'image/jpeg'
                  folderPath = "manga/#{program.manga}/#{program.manga}-#{paddedVol}-#{paddedEp}"
                  fileName   = "#{padding(i, 3)}.jpg"
                  filePath   = "./#{folderPath}/#{fileName}"

                  createFolder(folderPath)
                  request(uri: imgUri, timeout: 120 * 1000)
                    .pipe fs.createWriteStream(filePath)
                    .on 'finish', ->
                      pages.splice(pages.indexOf(i), 1)

                      # Since iOS seems to sort images by created date, this should do the trick.
                      # Also rounds this by 60 (minutes)
                      exec("touch -t #{moment().format('YYYYMMDD')}#{padding(~~(i / 60), 2)}#{padding(i % 60, 2)} #{filePath}")

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
      host = mangaUrls[name].url.match(/http:\/\/[.\w\d]+\//) || []
      host = host[0]

      request uri: "#{mangaUrls[name].url}/", followRedirect: false, (err, res, body) ->
        $          = cheerio.load(body)
        label      = switch host
                     when 'http://mangafox.me/' then $('a.tips').first().text().trim()
                     else                            $('div.detail_list span.left a.color_0077').first().text().trim()
        labelNum   = ~~(_.last(label.split(' ')))
        folderPath = "./manga/#{name}"

        if fs.existsSync(folderPath)
          fs.readdir folderPath, (e, folders) ->
            _.remove(folders, (x) -> x is '.DS_Store')
            latestFolder = ~~(_.last(_.last(folders).split('-'))) if folders.length
            color = if latestFolder is labelNum then clc.green else clc.red

            console.log "#{label} [#{clc.yellow name}] (local: #{color(latestFolder || '-')}/#{labelNum})"

episodeList = ->
  unless program.manga
    console.log 'Error: please specify manga'
    return

  request uri: "#{mangaUrls[program.manga]}/", followRedirect: false, (err, res, body) ->
    $ = cheerio.load(body)
    $('div.detail_list ul span.left').each (i, l) ->
      text = @parent().text().trim()
        .replace(/\r?\n|\r|\t/g, '')
        .replace(/\s{2,}/g, ' | ')
      console.log text

##############################################################################
# App Kickoff!
##############################################################################

if program.list then mangaList()
else if program.eplist then episodeList()
else if program.manga and program.episode
  episodes =  [program.episode[0]..(program.episode[1] || program.episode[0])]
  for ep in episodes
    mangaDownload(program.volume || 0, ep.toString())
else
  console.log 'Error: please specify manga, volume and episode'
