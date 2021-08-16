local SimpleECS = require 'lib.ecs'

local drawSystem = SimpleECS.System('sprite', 'position')

local atlas = love.graphics.newImage('assets/atlas.png')

local Context, camera = nil, nil

function drawSystem:init()
    Context = self.context
    camera  = Context.camera
end

function drawSystem:draw()
    camera:attach(0, 0, 320, 180)

    for entity in self.pool:elements() do
        local position = Context:getComponent(entity, 'position')
        local sprite   = Context:getComponent(entity, 'sprite')

        love.graphics.draw(atlas, sprite, position.x, position.y)
    end

    camera:detach()
end

return drawSystem