local PATH = (...):gsub('%.init$', '')

local gamestates = {}

gamestates.level = require(PATH .. '.level')

return gamestates