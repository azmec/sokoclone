--- Level editor gamestate. Allows the user to edit levels 5head.

local min, max    = math.min, math.max
local sin, cos    = math.sin, math.cos
local floor, ceil = math.floor, math.ceil

local Camera = require 'lib.hump.camera'
local Map    = require 'src.map'
local ATLAS  = require 'src.atlas'

local TILES        = ATLAS.TILES
local TILE_SIZE    = ATLAS.TILE_SIZE
local FONT_HEIGHT  = ATLAS.FONT_HEIGHT

-- A level can only be as big as the screen is. This is a design choice;
-- puzzles 'feel' better if I can see everything all the time.
local LIMITS       = { TOP = 0, LEFT = 0, RIGHT = 320, BOTTOM = 180}
local LEVEL_WIDTH  = 20 -- Width in cell units.
local LEVEL_HEIGHT = 11 -- Height in cell units.

local camera = Camera.new()
-- We're just aiming for function right now.
-- We'll consider dynamically resizing our levels and get reading/writing
-- up and running later.
local level  = { name = '[NO LEVEL]', data = {} }

local function placeTile(x, y, i)
    level.data[y][x] = {
        id   = i,
        quad = ATLAS:quad(i)
    }
end

local Editor = {}

function Editor:init()
    -- Global editor data. If I want it, I get it.
    self.mouse  = { x = 0, y = 0 } -- Used to calculate camera panning.
    self.pmouse = { x = 0, y = 0 } -- Mouse coordinates from push translation.
    self.cmouse = { x = 0, y = 0 } -- Mouse location in tile/cell form.

    self.pressed = false -- If the left mouse button is pressed.
    self.time    = 0.0   -- How long the left mouse button was pressed.

    self.selected = 0                 -- Selected tile (see ATLAS.TILES)
    self.previous = { x = 0, y = 0 }  -- Previously placed tile (in cell units).
    self.paint    = false             -- If we're 'painting'.

    for y = 1, LEVEL_HEIGHT do
        level.data[y] = {}
        for x = 1, LEVEL_WIDTH do
            level.data[y][x] = {id = TILES.FLOOR, quad = ATLAS:quad(TILES.FLOOR)}
        end
    end
end

function Editor:enter(previous, level_path)
    love.graphics.setFont(ATLAS.FONT)
    love.graphics.setBackgroundColor(1, 1, 0)
end

function Editor:leave()
end

function Editor:resume()
end

function Editor:update(delta)
    -- Camera panning.
    local mouse          = self.mouse
    local new_mx, new_my = love.mouse.getPosition()
    new_mx, new_my = new_mx / 4, new_my / 4 -- Scaling from 1080x720 to 320x180; TODO: Dynamically get scale.

    if love.mouse.isDown(3) then
        local angle  = camera.rot
        local si, co = sin(angle), cos(angle)
        local dx     = (-new_mx + mouse.x)
        local dy     = (-new_my + mouse.y)
        local cx, cy = camera:position()

        camera:lookAt(cx + dx * co - dy * si, cy + dy * co + dx * si)
        camera.x, camera.y = floor(camera.x), floor(camera.y)
    end

    mouse.x, mouse.y = new_mx, new_my

    if love.mouse.isDown(1) then self.time = self.time + delta
    else self.time = 0.0 end

    if self.time > 0 and (self.cmouse.x ~= self.previous.x or self.cmouse.y ~= self.previous.y) then
        placeTile(self.cmouse.x, self.cmouse.y, self.selected)
        self.previous.x, self.previous.y = self.cmouse.x, self.cmouse.y
    end
end

function Editor:draw()
    local camx, camy = camera:position()
    local pmouse     = self.pmouse
    local cmouse     = self.cmouse

    camera:attach(0, 0, 320, 180)

    -- Rendering the map.
    love.graphics.setColor(1, 1, 1)
    for y = 1, LEVEL_HEIGHT do
        for x = 1, LEVEL_WIDTH do
            local quad = level.data[y][x].quad
            love.graphics.draw(ATLAS.IMAGE, quad, (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)
        end
    end

    -- Drawing the 'preview' of tile.
    local tile = ATLAS:quad(self.selected)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.draw(ATLAS.IMAGE, tile, (cmouse.x - 1) * 16, (cmouse.y - 1) * 16)

    camera:detach()

    -- Drawing the grid.
    love.graphics.push()
    love.graphics.translate(320 / 2, 180 / 2)
    love.graphics.translate(-camx, -camy)

    -- Drawing border box.
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle('line', LIMITS.LEFT, LIMITS.TOP, LIMITS.RIGHT, LIMITS.BOTTOM)

    local x_lines = floor(180 / TILE_SIZE) -- Lines parallel to x axis.
    local y_lines = floor(320 / TILE_SIZE) -- Lines parallel to y axis.

    love.graphics.setColor(1, 1, 1, 0.6)
    for y = 1, x_lines do love.graphics.line(0, y * TILE_SIZE, 320, y * TILE_SIZE) end
    for x = 1, y_lines do love.graphics.line(x * TILE_SIZE, 0, x * TILE_SIZE, 180) end

    love.graphics.pop()

    -- Drawing info/tool bar along the top.
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', LIMITS.LEFT, LIMITS.TOP, LIMITS.RIGHT, 16)

    love.graphics.setColor(1, 1, 1)
    --local msg = string.format('Camera Position: (%i, %i)', camx, camy)
    --love.graphics.print(msg, 10, 0)

    local mx, my = camera:worldCoords(pmouse.x, pmouse.y)
    mx, my       = mx + 480, my + 270 -- I have no clue why translations get scuffed.

    cmouse.x, cmouse.y = floor(mx / TILE_SIZE) + 1, floor(my / TILE_SIZE) + 1
    cmouse.x, cmouse.y = min(max(1, cmouse.x), 20), min(max(1, cmouse.y), 11) -- Clamping it to be within the map.
    local msg = string.format('Cell: (%i, %i)', cmouse.x, cmouse.y)
    love.graphics.print(msg, 5, 0)

    msg = ('Selected Tile: ' .. ATLAS.NAMES[self.selected + 1])
    love.graphics.print(msg, 120, 0)

    msg = ('Save: [c]')
    love.graphics.print(msg, 230, 0)

    msg = ('Play: [v]')
    love.graphics.print(msg, 280, 0)

    -- Drawing the level name along the bottom.
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', LIMITS.LEFT, LIMITS.BOTTOM - 16, LIMITS.RIGHT, LIMITS.BOTTOM)

    love.graphics.setColor(1, 1, 1)
    msg = ('Level: ' .. level.name)
    love.graphics.print(msg, 120, LIMITS.BOTTOM - 16)
end

function Editor:keypressed(key, scancode, isrepeat)
end

function Editor:keyreleased(key, scancode)
end

function Editor:mousepressed(x, y, button)
end

function Editor:mousereleased(x, y, button)
    local cmouse = self.cmouse
    if cmouse.x <= LEVEL_WIDTH and cmouse.y <= LEVEL_HEIGHT and button == 1 then
        placeTile(cmouse.x, cmouse.y, self.selected)
        self.previous.x, self.previous.y = cmouse.x, cmouse.y
    end
end

function Editor:mousemoved(x, y, dx, dy)
    self.pmouse.x, self.pmouse.y = x, y
end

function Editor:wheelmoved(x, y)
    local new = self.selected + y
    if new > #ATLAS.NAMES - 1 then new = 0
    elseif new < 0 then new = #ATLAS.NAMES - 1 end

    self.selected = new
end

function Editor:quit()
end

return Editor