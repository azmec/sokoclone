local SimpleECS = require 'lib.ecs'

local collisionSystem = SimpleECS.System('collision', 'position')

return collisionSystem