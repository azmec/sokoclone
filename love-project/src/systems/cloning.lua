local SimpleECS     = require 'lib.ecs'
local CloningSystem = SimpleECS.System('duplicator', 'position')

local Context
local boxes, players

-- Shared in level. TODO: Move to separate, requirable .lua file.
local TILE_SIZE    = 16
local ATLAS        = love.graphics.newImage('assets/atlas.png')
local ATLAS_WIDTH  = ATLAS:getWidth()
local ATLAS_HEIGHT = ATLAS:getHeight()

local function generateQuad(index)
    return love.graphics.newQuad(index * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, ATLAS_WIDTH, ATLAS_HEIGHT)
end

function CloningSystem:init()
    Context = self.context
    boxes   = Context:getGroup('boxes')
    players = Context:getGroup('players')
end

function CloningSystem:update(delta)
    for entity in self:entities() do
        local position   = Context:getComponent(entity, 'position')
        local duplicator = Context:getComponent(entity, 'duplicator')


        -- If a player is over the duplicator we're checking, check for
        -- previous cloning and clone appropiately.
        for player in players:entities() do
            local player_pos = Context:getComponent(player, 'position')
            if position.x == player_pos.x and position.y == player_pos.y
            and not duplicator.used then
                for other in self:entities() do
                    local dup = Context:getComponent(other, 'duplicator')
                    dup.used  = true

                    -- If it's not the duplicator we're currently
                    -- checking, clone the player at that location.
                    if entity ~= other then
                        local other_pos = Context:getComponent(other, 'position')

                        -- Clone the player.
                        local clone  = Context:entity()
                        local sprite = generateQuad(1)
                        Context:give(clone, 'position', other_pos.x, other_pos.y)
                        Context:give(clone, 'sprite', sprite)
                        Context:give(clone, 'input')
                        Context:give(clone, 'layer', 4)
                    end
                end
            end
        end
    end
end

return CloningSystem