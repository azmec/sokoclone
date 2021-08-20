--- Level editor gamestate. Allows the user to edit levels 5head.

local min, max    = math.min, math.max
local sin, cos    = math.sin, math.cos
local floor, ceil = math.floor, math.ceil

local Camera = require 'lib.hump.camera'
local Map    = require 'src.map'
local ATLAS  = require 'src.atlas'

local TILE_SIZE    = ATLAS.TILE_SIZE
local FONT_HEIGHT  = ATLAS.FONT_HEIGHT

-- A level can only be as big as the screen is. This is a design choice;
-- puzzles 'feel' better if I can see everything all the time.
local LIMITS = { TOP = 0, LEFT = 0, RIGHT = 320, BOTTOM = 180}

local camera = Camera.new()
local mouse  = { x = 0, y = 0 } -- Used to calculate camera panning.
local pmouse = { x = 0, y = 0 } -- Used to calculate cell and tile locations.

local Editor = {}

function Editor:init()
end

function Editor:enter(previous, level_path)
    love.graphics.setFont(ATLAS.FONT)
end

function Editor:leave()
end

function Editor:resume()
end

function Editor:update(delta)
    -- Camera panning.

    local new_mx, new_my = love.mouse.getPosition()
    new_mx, new_my = new_mx / 4, new_my / 4 -- Scaling from 1080x720 to 320x180; TODO: Dynamically get scale.

    if love.mouse.isDown(1) then
        local angle  = camera.rot
        local si, co = sin(angle), cos(angle)
        local dx     = (-new_mx + mouse.x)
        local dy     = (-new_my + mouse.y)
        local cx, cy = camera:position()

        camera:lookAt(cx + dx * co - dy * si, cy + dy * co + dx * si)
    end

    mouse.x, mouse.y = new_mx, new_my
end

function Editor:draw()
    local camx, camy = camera:position()

    -- Drawing the grid.
    love.graphics.push()
    love.graphics.translate(320 / 2, 180 / 2)
    love.graphics.translate(-camx, -camy)

    local x_lines = floor(180 / TILE_SIZE) -- Lines parallel to x axis.
    local y_lines = floor(320 / TILE_SIZE) -- Lines parallel to y axis.

    for y = 1, x_lines do love.graphics.line(0, y * TILE_SIZE, 320, y * TILE_SIZE) end
    for x = 1, y_lines do love.graphics.line(x * TILE_SIZE, 0, x * TILE_SIZE, 180) end

    love.graphics.pop()

    camera:attach(0, 0, 320, 180)

    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle('line', LIMITS.LEFT, LIMITS.TOP, LIMITS.RIGHT, LIMITS.BOTTOM)

    camera:detach()

    -- Drawing info/tool bar along the top.
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', LIMITS.LEFT, LIMITS.TOP, LIMITS.RIGHT, 16)

    love.graphics.setColor(1, 1, 1)
    local msg = string.format('Camera Position: (%i, %i)', camx, camy)
    love.graphics.print(msg, 10, 0)

    local mx, my = camera:worldCoords(pmouse.x, pmouse.y)
    mx, my       = mx + 480, my + 270 -- I have no clue why translations get scuffed.
    local msg = string.format('World Mouse Position: (%i, %i)', mx, my)
    --love.graphics.print(msg, 140, 0)

    local cx, cy = floor(mx / TILE_SIZE) + 1, floor(my / TILE_SIZE) + 1
    cx, cy       = min(max(1, cx), 20), min(max(1, cy), 11)
    msg = string.format('Cell: (%i, %i)', cx, cy)
    love.graphics.print(msg, 170, 0)
end

function Editor:keypressed(key, scancode, isrepeat)
end

function Editor:keyreleased(key, scancode)
end

function Editor:mousepressed(x, y, button)
end

function Editor:mousereleased(x, y, button)
end

function Editor:mousemoved(x, y, dx, dy)
    pmouse.x, pmouse.y = x, y
end

function Editor:wheelmoved(x, y)
end

function Editor:quit()
end

return Editor