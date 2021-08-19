--- Level editor gamestate. Allows the user to edit levels 5head.

local Map = require 'src.map'

local Editor = {}

local TILE_SIZE    = 16
local ATLAS        = love.graphics.newImage('assets/atlas.png')
local ATLAS_WIDTH  = ATLAS:getWidth()
local ATLAS_HEIGHT = ATLAS:getHeight()

local FONT        = love.graphics.newFont('assets/bitty.ttf', 16)
local FONT_HEIGHT = FONT:getHeight('A')

local mouse = {
    x  = 0,
    y  = 0,
    dx = 0,
    dy = 0
}

local CURRENT_TILE = 0

local function clamp(x, lo, hi) return math.min(math.max(lo, x), hi) end

local function generateQuad(index)
    return love.graphics.newQuad(index * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, ATLAS_WIDTH, ATLAS_HEIGHT)
end

function Editor:init()
end

function Editor:enter(previous, level)
    love.graphics.setFont(FONT)

    self.map    = Map(level)
    self.canvas = {}

    for x, y in self.map:cells() do
        local i    = self.map:getValue(x, y)
        local quad = generateQuad(i)

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
        love.graphics.draw(ATLAS, quad, x * TILE_SIZE, y * TILE_SIZE)
    end

    love.graphics.rectangle('fill', mouse.x, mouse.y, 4, 4)

    local cx, cy = mouse.x / TILE_SIZE, mouse.y / TILE_SIZE
    local msg = string.format('Mouse: (%i, %i)', cx, cy)
    love.graphics.print(msg, 320 / 2, 10)

    local msg = string.format('Selected tile: %i', CURRENT_TILE)
    love.graphics.print(msg, 320 / 2, 10 + (FONT_HEIGHT / 2))

    local msg = string.format('Save: j')
    love.graphics.print(msg, 320 / 2, 10 + (FONT_HEIGHT * 1.5))

    local msg = string.format('Play: k')
    love.graphics.print(msg, 320 / 2, 10 + (FONT_HEIGHT * 2))
end

function Editor:keypressed(key, scancode, isrepeat)
end

function Editor:keyreleased(key, scancode)
end

function Editor:mousepressed(x, y, button)
end

function Editor:mousereleased(x, y, button)
    local cx, cy = math.floor(x / TILE_SIZE), math.floor(y / TILE_SIZE)
    if cx <= self.map:getWidth() and cy <= self.map:getHeight() then
        self.map:setValue(cx, cy, CURRENT_TILE)
        self.canvas[cy][cx] = generateQuad(CURRENT_TILE)
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