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
mangaUrls = require('./database')

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
  .option('-w, --ver <value>', 'Specify version')
  .parse(process.argv)

##############################################################################
# Image Downloading Functions
##############################################################################

# Shared variables
pages      = {}
pageAmount = {}
host       = undefined
host       = undefined

padding = (value, length) ->
  String(('0' for i in [0...length]).join('') + value).slice(length * -1)

createFolder = (folderPath) ->
  for path in folderPath.split '/'
    initPath = "#{initPath || '.'}/#{path}"
    fs.mkdirSync(initPath) unless fs.existsSync(initPath)

imageDownload = (imgUri, i, paddedVol, paddedEp, ep) ->
  request.head uri: imgUri, followRedirect: false, (err2, res2, body2) ->
    if err2 or res2.statusCode isnt 200
      console.log clc.red "Oops, something went wrong. Error: #{err2}"
      return false
    if res2.headers['content-type'] is 'image/jpeg'
      folderPath  = "manga/#{program.manga}/#{program.manga}-#{paddedVol}-#{paddedEp}"
      folderPath += "-#{program.pages}" if host is 'http://mangapark.com/' and program.pages
      fileName    = "#{padding(i, 3)}.jpg"
      filePath    = "./#{folderPath}/#{fileName}"

      createFolder(folderPath)
      request(uri: imgUri, timeout: 120 * 1000)
        .pipe fs.createWriteStream(filePath)
        .on 'finish', ->
          pages[ep].splice(pages[ep].indexOf(i), 1)

          # Since iOS seems to sort images by created date, this should do the trick.
          # Also rounds this by 60 (minutes)
          exec("touch -t #{moment().format('YYYYMMDD')}#{padding(~~(i / 60), 2)}#{padding(i % 60, 2)} #{filePath}")

          if pages[ep].length is 0
            console.log clc.green "\nDone ##{ep}!"
          else if pages[ep].length > 3
            if (pageAmount[ep] - pages[ep].length) % 5
              process.stdout.write "."
            else
              process.stdout.write "#{pageAmount[ep] - pages[ep].length}"
          else
            process.stdout.write "\nRemaining (##{ep}): #{pages[ep].join(', ')}" if pages[ep].length

mangaDownload = (vol, ep) ->
  fraction  = if ep.match /\./ then _.last(ep.split('.')) else false
  ep        = ep.split('.')[0]
  format    = mangaUrls[program.manga].format
  format    = 4 if format is 2 and not vol
  uri       = switch format
              when 1 then "#{mangaUrls[program.manga].url}/v#{if vol is 'TBD' then 'TBD' else padding(vol, 2)}/c#{padding(ep, 3)}/"
              when 2 then "#{mangaUrls[program.manga].url}/v#{vol}/c#{ep}/"
              when 3 then "#{mangaUrls[program.manga].url}/v#{padding(vol, 2)}/c#{padding(ep, 3)}#{if fraction then '.' + fraction else ''}/"
              when 4 then "#{mangaUrls[program.manga].url}/c#{ep}/"
              else        "#{mangaUrls[program.manga].url}/c#{padding(ep, 3)}#{if fraction then '.' + fraction else ''}/"
  uri      += "e#{program.ver}/" if program.ver
  paddedVol = padding(vol, 3)
  paddedEp  = padding(ep, 3)
  paddedEp += ".#{fraction}" if fraction
  host      = mangaUrls[program.manga].url.match(/http:\/\/[.\w\d]+\//) || []
  host      = host[0]

  if host is 'http://mangapark.com/'
    if program.pages
      uri += "10-#{program.pages}"
    else
      uri += 'all'

  console.log uri

  request uri: uri, (err, res, body) ->
    if err or res.statusCode isnt 200
      console.log clc.red "Oops, something went wrong #{'(Error: ' + res.statusCode + ')'if res}"
      return false

    $ = cheerio.load(body)

    # Tap-in for mangapark.com
    if host.match(/mangapark/)
      imgs           = $('img.img')
      pages[ep]      = imgs.map (i) -> i
      pageAmount[ep] = pages[ep].length
      imgs.each (i) -> imageDownload @attr('src'), i, paddedVol, paddedEp, ep

    # Other sites
    else
      pageAmount[ep] = switch host
                   when 'http://mangafox.me/' then $('form#top_bar select.m option').length
                   else                            $('section.readpage_top select.wid60 option').length
      pages[ep] = program.pages || [0..pageAmount[ep]]
      # uri = uri.slice(0, -1) if uri.match /\/$/  # Remove trailing `/`

      console.log clc.green "Downloading up to #{pages[ep].length} page(s)"
      for i in _.clone pages[ep]
        do (i) ->
          request uri: "#{uri}#{ if i > 0 then i + '.html' else ''  }", followRedirect: false, (err, res, body) ->
            $$ = cheerio.load(body)

            if err or res.statusCode isnt 200
              pages[ep].splice(pages[ep].indexOf(i), 1)
            else
              img = $$('img#image')

              unless img.length
                pages[ep].splice(pages[ep].indexOf(i), 1)
              else
                imgUri = switch host
                         when 'http://mangafox.me/' then img.attr('onerror').match(/http.+jpg/)[0]  # New manga seems to fallback to another CDN
                         else                            img.attr('src')

                # Rerender mode for mangahere
                imgUri = switch program.rerender
                         when '0' then imgUri.replace(/.\.m.cdn\.net/, 'm.mhcdn.net')
                         when '1' then imgUri.replace(/.\.m.cdn\.net/, 's.mangahere.com')
                         when '2' then imgUri.replace(/.\.m.cdn\.net/, 'z.mfcdn.net')
                         else          imgUri

                console.log imgUri if program.pages
                imageDownload imgUri, i, paddedVol, paddedEp, ep

mangaList = ->
  for name, url of mangaUrls
    do (name, url) ->
      _host = mangaUrls[name].url.match(/http:\/\/[.\w\d]+\//) || []
      _host = _host[0]

      request uri: "#{mangaUrls[name].url}/", followRedirect: true, (err, res, body) ->
        $          = cheerio.load(body)
        label      = switch _host
                     when 'http://mangafox.me/'   then $('a.tips').first().text().trim()
                     when 'http://mangapark.me/' then $('.stream:last-child ul.chapter li span a').first().text().trim().replace(/\n/, '').replace(/(\s+|\t)/, ' ')
                     else                              $('div.detail_list span.left a.color_0077').first().text().trim()
        labelNum   = _.last(label.split(' '))
        labelNum   = ~~(_.last(labelNum.split('.')))
        folderPath = "./manga/#{name}"

        if fs.existsSync(folderPath)
          fs.readdir folderPath, (e, folders) ->
            _.remove(folders, (x) -> x is '.DS_Store')
            latestFolder = ~~(_.last(_.last(folders).split('-'))) if folders.length
            color = if latestFolder is labelNum then clc.green else clc.red

            console.log "[#{clc.yellow name}] #{label} (local: #{color(if latestFolder? then latestFolder else '-')}/#{labelNum})"

episodeList = ->
  unless program.manga
    console.log 'Error: please specify manga'
    return

  request uri: "#{mangaUrls[program.manga].url}/", followRedirect: false, (err, res, body) ->
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
