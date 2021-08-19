local PATH = (...):gsub('%.init$', '')

local gamestates = {}

gamestates.level  = require(PATH .. '.level')
gamestates.editor = require(PATH .. '.editor')

return gamestates