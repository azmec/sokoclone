--- Level editor gamestate. Allows the user to edit levels 5head.

local floor, min, max = math.floor, math.min, math.max

local Map   = require 'src.map'
local ATLAS = require 'src.atlas'
local write = require 'src.write'

local TILE_SIZE    = ATLAS.TILE_SIZE
local FONT_HEIGHT  = ATLAS.FONT_HEIGHT
local LEVEL_NAME   = ''
local CURRENT_TILE = 0

local mouse = {
    x  = 0,
    y  = 0,
    dx = 0,
    dy = 0
}

local Editor = {}

local function clamp(x, lo, hi) return min(max(lo, x), hi) end

function Editor:init()
end

function Editor:enter(previous, level_path)
    love.graphics.setFont(ATLAS.FONT)

    local level, message = love.filesystem.load(level_path)
    if not level then error(message) end

    LEVEL_NAME = level_path

    self.map    = Map(level())
    self.canvas = {}

    for x, y in self.map:cells() do
        local i    = self.map:getValue(x, y)
        local quad = ATLAS:quad(i)

        if not self.canvas[y] then self.canvas[y] = {} end
        self.canvas[y][x] = quad
    end
end

function Editor:leave()
end

function Editor:resume()
end

function Editor:update(delta)
end

function Editor:draw()
    for x, y in self.map:cells() do
        local quad = self.canvas[y][x]
        love.graphics.draw(ATLAS.IMAGE, quad, x * TILE_SIZE, y * TILE_SIZE)
    end

    love.graphics.rectangle('fill', mouse.x, mouse.y, 4, 4)

    local msg = "Current level: " .. LEVEL_NAME
    love.graphics.print(msg, 320 / 2, 10)

    local cx, cy = mouse.x / TILE_SIZE, mouse.y / TILE_SIZE
    local msg = string.format('Mouse: (%i, %i)', cx, cy)
    love.graphics.print(msg, 320 / 2, 20)

    local msg = string.format('Selected tile: %i', CURRENT_TILE)
    love.graphics.print(msg, 320 / 2, 20 + (FONT_HEIGHT / 2))

    local msg = string.format('Save: j')
    love.graphics.print(msg, 320 / 2, 20 + (FONT_HEIGHT * 1.5))

    local msg = string.format('Play: k')
    love.graphics.print(msg, 320 / 2, 20 + (FONT_HEIGHT * 2))
end

function Editor:keypressed(key, scancode, isrepeat)
end

function Editor:keyreleased(key, scancode)
    if key == 'j' then
        local data = write.tostring(self.map.data)
        local success, message = love.filesystem.write(LEVEL_NAME, data)
        if not success then error(message) end
    end
end

function Editor:mousepressed(x, y, button)
end

function Editor:mousereleased(x, y, button)
    local cx, cy = floor(x / TILE_SIZE), floor(y / TILE_SIZE)
    if cx <= self.map:getWidth() and cy <= self.map:getHeight() then
        self.map:setValue(cx, cy, CURRENT_TILE)
        self.canvas[cy][cx] = ATLAS:quad(CURRENT_TILE)
    end
end

function Editor:mousemoved(x, y, dx, dy)
    mouse.x, mouse.y, mouse.dx, mouse.dy = x, y, dx, dy
end

function Editor:wheelmoved(x, y)
    local new = CURRENT_TILE + y
    if new > 5 then new = 0
    elseif new < 0 then new = 5 end

    CURRENT_TILE = new
end

function Editor:quit()
end

return Editor