#!/usr/bin/env coffee

fs      = require('fs')
request = require('request')
program = require('commander')
async   = require('async')
_       = require('lodash')
exec    = require('child_process').exec
moment  = require('moment')

program
  .version('0.0.1')
  .usage('-m [manga ex. bleach] -v [volume ex. 30] -e [episode ex. 268]')
  .option('-m, --manga <value>', 'Specify manga, currently available are [bleach, sk, sk-f, nisekoi, denpa-kyoushi, trinity-seven]')
  .option('-v, --volume <n>', 'Specify volume')
  .option('-e, --episode <n>', 'Specify episode')
  .option('-p, --pages [items]', 'Specify pages (optional) e.g. -p 2,4,5', (val) -> val.split(','))
  .option('-n, --amount [n]', 'Specify amount (optional) e.g. -n 3')
  .parse(process.argv)

##############################################################################
# Image Downloading Functions
##############################################################################

padding = (value, length) ->
  String(('0' for i in [0...length]).join('') + value).slice(length * -1)

downloadEp = (vol, ep) ->
  now = new Date()
  pageAmount = program.amount || switch program.manga
    when 'sk-f'          then 50
    when 'nisekoi'       then 60
    when 'denpa-kyoushi' then 70
    when 'trinity-seven' then 50
    else 30
  pages = program.pages || [0..pageAmount]

  for i in _.clone pages
    do (i) ->
      uri = switch program.manga
        when 'bleach'        then "http://mangafox.me/manga/bleach/v#{padding(vol, 2)}/c#{padding(ep, 3)}/#{i}.html"
        when 'sk'            then "http://www.mangahere.com/manga/shaman_king/v#{vol}/c#{ep}/#{i}.html"
        when 'sk-f'          then "http://www.mangahere.com/manga/shaman_king_flowers/c#{padding(ep, 3)}/#{i}.html"
        when 'nisekoi'       then "http://www.mangahere.com/manga/nisekoi_komi_naoshi/c#{padding(ep, 3)}/#{i}.html"
        when 'denpa-kyoushi' then "http://www.mangahere.com/manga/denpa_kyoushi/c#{padding(ep, 3)}/#{i}.html"
        when 'trinity-seven' then "http://www.mangahere.com/manga/trinity_seven/c#{padding(ep, 3)}/#{i}.html"

      request uri: uri, followRedirect: false, (err, res, body) ->
        paddedVol = padding(vol, 3)
        paddedEp = padding(ep, 3)

        if err or res.statusCode isnt 200
          pages.splice(pages.indexOf(i), 1)
        else
          folderPath = "manga/#{program.manga}/#{program.manga}-#{paddedVol}-#{paddedEp}"
          for path in folderPath.split '/'
            initPath = "#{initPath || '.'}/#{path}"
            fs.mkdirSync(initPath) unless fs.existsSync(initPath)

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
              if res2.headers['content-type'] is 'image/jpeg'
                nowOffset = new Date(now.setMinutes(i))
                fileName = "#{padding(i, 2)}.jpg"
                filePath = "#{folderPath}/#{fileName}"

                request(uri: imgUri, timeout: 120 * 1000)
                  .pipe fs.createWriteStream(filePath)
                  .on 'finish', ->
                    pages.splice(pages.indexOf(i), 1)
                    console.log "Remaining: #{pages.join(', ')}" if pages.length
                    exec("touch -t #{moment().format('YYYYMMDD')}#{padding(i, 4)} #{filePath}")  # Since iOS seems to sort images by created date, this should do the trick

##############################################################################
# App Kickoff!
##############################################################################

if program.manga and program.volume and program.episode
  downloadEp(program.volume, program.episode)
else
  console.log 'Error: please specify manga, volume and episode'
