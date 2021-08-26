local PATH = (...):gsub('%.init$', '')

local gamestates = {}

gamestates.level  = require(PATH .. '.level')
gamestates.editor = require(PATH .. '.editor')
gamestates.write  = require(PATH .. '.write')

return gamestates