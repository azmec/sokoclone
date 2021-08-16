local SimpleECS = require 'lib.ecs'

local drawSystem = SimpleECS.System('sprite', 'position')

function drawSystem:draw()
    local Context = self.context
    for entity in self.pool:elements() do
        local position = Context:getComponent('position', entity)

        love.graphics.rectangle('fill', position.x, position.y, 16, 16)
    end
end

return drawSystem