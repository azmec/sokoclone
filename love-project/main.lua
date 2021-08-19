local Gamestate = require 'lib.hump.gamestate'
local push      = require 'lib.push'

local gamestates = require 'src.gamestates'

local WINDOW_SCALE = 4 -- Window multiplier.

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

    Gamestate.switch(gamestates.level)
end

function love.update(delta)
    Gamestate.update(delta)
end

function love.draw()
    push:start()

    Gamestate.draw()

    push:finish()
end

function love.keypressed(key, scancode, isrepeat)
    Gamestate.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    Gamestate.keyreleased(key, scancode)
end

function love.resize(width, height)
    push:resize(width, height)
end