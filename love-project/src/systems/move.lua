--- Moves the player(s) based on input position of boxes and walls.
-- Supah messy, but it works. TODO: Clean up.

local SimpleECS  = require 'lib.ecs'
local moveSystem = SimpleECS.System('position', 'input')

local COOLDOWN  = 0.125
local moveTimer = 0.0

local Context
local boxes, walls

function moveSystem:init()
    Context = self.context
    boxes   = Context:getGroup('boxes')
    walls   = Context:getGroup('walls')
end

function moveSystem:update(delta)
    local x_input, y_input = Context.input:get('move')
    moveTimer              = moveTimer - delta

    for entity in self.pool:elements() do
        local position = Context:getComponent(entity, 'position')

        local new_x, new_y = position.x, position.y
        if moveTimer <= 0 and (x_input ~= 0 or y_input ~= 0) then
            new_x     = position.x + (16 * x_input)
            new_y     = position.y + (16 * y_input)

        local can_move     = true
        for wall in walls:entities() do
            local wall_pos = Context:getComponent(wall, 'position')
            if new_x == wall_pos.x and new_y == wall_pos.y then can_move = false end
        end

        for box in boxes:entities() do
            local box_pos = Context:getComponent(box, 'position')
            if new_x == box_pos.x and new_y == box_pos.y then
                local new_box_x = new_x + (16 * x_input)
                local new_box_y = new_y + (16 * y_input)

                for wall in walls:entities() do
                    local wall_pos = Context:getComponent(wall, 'position')
                    if new_box_x == wall_pos.x and new_box_y == wall_pos.y then
                        can_move = false
                    end
                end
                for otherBox in boxes:entities() do
                    local otherBox_pos = Context:getComponent(otherBox, 'position')
                    if new_box_x == otherBox_pos.x and new_box_y == otherBox_pos.y then
                        can_move = false
                    end
                end

                if can_move then
                    box_pos.x = new_box_x
                    box_pos.y = new_box_y
                end
            end
        end

        if can_move then
            position.x, position.y = new_x, new_y
        end
        end
    end

    if moveTimer <= 0 and (x_input ~= 0 or y_input ~= 0) then moveTimer = COOLDOWN end
end

return moveSystem