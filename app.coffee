#!/usr/bin/env coffee

fs = require('fs')
request = require('request')
program = require('commander')
async = require('async')
_ = require('lodash')

program
  .version('0.0.1')
  .usage('-m [manga ex. bleach] -v [volume ex. 30] -e [episode ex. 268]')
  .option('-m, --manga <value>', 'Specify manga, currently available are [bleach, sk, sk-f, nisekoi]')
  .option('-v, --volume <n>', 'Specify volume')
  .option('-e, --episode <n>', 'Specify episode')
  .option('-n, --amount [n]', 'Specify amount (optional)')
  .parse(process.argv)

##############################################################################
# Image Downloading Functions
##############################################################################

padding = (value, length) ->
  String(('0' for i in [0...length]).join('') + value).slice(length * -1)

downloadEp = (vol, ep) ->
  now = new Date()
  pageAmount = program.amount || switch program.manga
    when 'sk-f' then 50
    when 'nisekoi' then 60
    else 30

  for i in [0..pageAmount]
    do (i) ->
      fileName = "#{padding(i, 2)}.jpg"

      uri = switch program.manga
        when 'bleach'  then "http://mangafox.me/manga/bleach/v#{padding(vol, 2)}/c#{padding(ep, 3)}/#{i}.html"
        when 'sk'      then "http://www.mangahere.com/manga/shaman_king/v#{vol}/c#{ep}/#{i}.html"
        when 'sk-f'    then "http://www.mangahere.com/manga/shaman_king_flowers/c#{padding(ep, 3)}/#{i}.html"
        when 'nisekoi' then "http://www.mangahere.com/manga/nisekoi_komi_naoshi/c#{padding(ep, 3)}/#{i}.html"

      request uri: uri, followRedirect: false, (err, res, body) ->
        paddedVol = padding(vol, 3)
        paddedEp = padding(ep, 3)

        if !err and res.statusCode == 200
          folderPath = "manga/#{program.manga}/#{paddedVol}-#{paddedEp}"
          for path in folderPath.split '/'
            initPath = "#{initPath || '.'}/#{path}"
            fs.mkdirSync(initPath) unless fs.existsSync(initPath)

          pattern = switch program.manga
            when 'bleach' then      /http:\/\/z.mfcdn.net\/store\/manga\/9\/.+\/compressed\/.+\.jpg"/
            when 'sk'     then     /http:\/\/z.mhcdn.net\/store\/manga\/65\/.+\/compressed\/.+\.jpg/
            when 'sk-f'   then   /http:\/\/z.mhcdn.net\/store\/manga\/6712\/.+\/compressed\/.+\.jpg/
            when 'nisekoi' then  /http:\/\/z.mhcdn.net\/store\/manga\/8945\/.+\/compressed\/.+\.jpg/

          if img = body.match pattern
            img_uri = img[0]
            img_uri = img_uri.slice(0, -1) if img_uri.match /"$/ # Remove trailing `"`

            request.head img_uri, (err2, res2, body2) ->
              if res2.headers['content-type'] is 'image/jpeg'
                console.log "Downloading #{fileName}"

                nowOffset = new Date(now.setMinutes(i))
                filePath = "#{folderPath}/#{fileName}"

                request(uri: img_uri, timeout: 120 * 1000)
                  .pipe fs.createWriteStream(filePath)
                  .on 'finish', -> fs.utimesSync filePath, nowOffset, nowOffset

##############################################################################
# App Kickoff!
##############################################################################

if program.manga and program.volume and program.episode
  downloadEp(program.volume, program.episode)
else
  console.log 'Error: please specify manga, volume and episode'
