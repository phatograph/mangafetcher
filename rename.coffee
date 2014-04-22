fs = require 'fs'
folders = fs.readdirSync("#{__dirname}/manga")
for f in folders when f[0] isnt '.'
  do (f) ->
    folderPath = "#{__dirname}/manga/#{f}"
    files = fs.readdirSync folderPath
    for fi in files when fi[0] isnt '.'
      do (fi) ->
        reg = /[a-z]-[a-z]/
        if fi.match reg
          oldPath = "#{folderPath}/#{fi}"
          newName = fi.replace reg, (match) ->
            match = match.split '-'
            "#{match[0]}_#{match.splice(-1)[0]}"

          fs.renameSync oldPath, "#{folderPath}/#{newName}"
