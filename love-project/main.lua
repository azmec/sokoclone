local Gamestate = require 'lib.hump.gamestate'
local push      = require 'lib.push'

local gamestates = require 'src.gamestates'

local WINDOW_SCALE = 4 -- Window multiplier.

local function loadDirectory(path, t)
    local info = love.filesystem.getInfo(path)
    if info == nil or info.type ~= 'directory' then
        error("bad argument #1 to 'loadDirectory' (path '".. path .."' not found)", 2)
    end

    local files = love.filesystem.getDirectoryItems(path)

    for i = 1, #files do
        local file      = files[i]
        local name      = file:sub(1, #file - 4) -- #'.lua'
        local file_path = path .. '.' .. name
        local value     = require(file_path)

        t[name] = value
    end

    return t
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

    local levels = loadDirectory('src/maps', {})
    Gamestate.switch(gamestates.level, 'test.lua')
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
    if key == 'space' then Gamestate.switch(gamestates.editor, 'test.lua')
    elseif key == 'escape' then Gamestate.switch(gamestates.level, 'test.lua') end
    Gamestate.keyreleased(key, scancode)
end

function love.mousepressed(x, y, button)
    x, y = push:toGame(x, y)
    Gamestate.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    x, y = push:toGame(x, y)
    Gamestate.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    x, y   = push:toGame(x, y)
    dx, dy = push:toGame(dx, dy)
    Gamestate.mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    Gamestate.wheelmoved(x, y)
end

function love.resize(width, height)
    push:resize(width, height)
end