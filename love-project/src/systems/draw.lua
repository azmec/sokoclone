local deep       = require 'lib.deep'
local SimpleECS  = require 'lib.ecs'
local drawSystem = SimpleECS.System('sprite', 'position', 'layer')

local atlas = love.graphics.newImage('assets/atlas.png')

local Context, camera = nil, nil

function drawSystem:init()
    Context = self.context
    camera  = Context.camera
end

function drawSystem:draw()
    camera:attach(0, 0, 320, 180)

    for entity in self:entities() do
        local layer    = Context:getComponent(entity, 'layer')
        local position = Context:getComponent(entity, 'position')
        local sprite   = Context:getComponent(entity, 'sprite')

        deep.queue(layer, love.graphics.draw, atlas, sprite, position.x, position.y)
    end

    deep.execute()

    camera:detach()
end

return drawSystem