local SimpleECS = require 'lib.ecs'
local Gamestate = require 'lib.hump.gamestate'
local Camera    = require 'lib.hump.camera'
local push      = require 'lib.push'

-- All available gamestates in one table.
local gamestates = require 'src.gamestates'

local WINDOW_SCALE = 4 -- Window multiplier.
local Context      = SimpleECS.Context()
local camera       = Camera.new()

-- Exposing camera to systems.
Context.camera = camera

local level = {
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 4, 0, 0, 0, 0 },
    { 0, 0, 2, 3, 0, 0, 0, 0 },
    { 0, 0, 2, 2, 2, 3, 1, 0 },
    { 0, 4, 2, 3, 3, 4, 0, 0 },
    { 0, 0, 0, 0, 2, 0, 0, 0 },
    { 0, 0, 0, 0, 4, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
}

local loadMap = function(map)
    local height, width = #map, #map[1]

    for y = 1, height do
        for x = 1, width do
            -- Tile values double as their sprite's position in the atlas.
            local tile = map[y][x]
            local quad = love.graphics.newQuad(tile * 16, 0, 16, 16, 128, 16)

            local entity = Context:entity()
            Context:give(entity, 'position', (x - 1) * 16, (y - 1) * 16)
            Context:give(entity, 'sprite', quad)
        end
    end
end

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    -- Getting window settings from conf.
    local game_width, game_height, flags = love.window.getMode()
    local window_width, window_height    = game_width * WINDOW_SCALE,
                                           game_height * WINDOW_SCALE

    push:setupScreen(game_width, game_height, window_width, window_height,
                     {
                         fullscreen   = flags.fullscreen,
                         resizable    = flags.resizable,
                         pixelperfect = true
                     })

    -- Retrieving all components and systems in single tables.
    local Components = SimpleECS.utils.packDirectory('src/components', {})
    local Systems    = SimpleECS.utils.packDirectory('src/systems', {})

    Context:registerComponents(Components)
    Context:registerSystems(Systems)

    loadMap(level)

    Context:emit('init')
end

function love.update(delta)
    Context:flush()
    Context:emit('update', delta)
end

function love.draw()
    push:start()

    Context:emit('draw')

    push:finish()
end

function love.resize(width, height)
    push:resize(width, height)
end