local SimpleECS  = require 'lib.ecs'
local goalSystem = SimpleECS.System('goal', 'position')

local Context, boxes

function goalSystem:init() Context = self.context boxes = Context:getGroup('boxes') end

function goalSystem:update(delta)
    for entity in self:entities() do
        local position = Context:getComponent(entity, 'position')
        local goal     = Context:getComponent(entity, 'goal')

        -- Loop through all boxes and check for matching position.
        -- If they're overtop, the goal plate is 'met.'
        for box in boxes:entities() do
            local box_pos = Context:getComponent(box, 'position')
            if position.x == box_pos.x and position.y == box_pos.y then
                if not goal.met then print('Goal met at (' .. position.x / 16 .. ', ' .. position.y / 16 .. ')!') end
                goal.met = true
            end
        end
    end
end

return goalSystem