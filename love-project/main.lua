local SimpleECS = require 'lib.ecs'
local Gamestate = require 'lib.hump.gamestate'
local Camera    = require 'lib.hump.camera'
local push      = require 'lib.push'

-- All available gamestates in one table.
local gamestates = require 'src.gamestates'

local WINDOW_SCALE = 4 -- Window multiplier.
local Context      = SimpleECS.Context()
local Camera       = Camera.new()

function love.load()
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
end

function love.update(delta)
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