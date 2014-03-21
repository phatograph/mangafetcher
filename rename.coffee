fs = require 'fs'
folders = fs.readdirSync(__dirname)
folders = (f for f in folders when f.match /kancolle-/)
for f in folders
  oldName = "#{__dirname}/#{f}"
  newName = oldName.replace /kancolle-/, 'kancolle_'
  fs.renameSync oldName, newName
