--- Level editor gamestate. Allows the user to edit levels 5head.

local min, max    = math.min, math.max
local sin, cos    = math.sin, math.cos
local floor, ceil = math.floor, math.ceil

local Camera    = require 'lib.hump.camera'
local Gamestate = require 'lib.hump.gamestate'
local Map       = require 'src.map'
local ATLAS     = require 'src.atlas'
local save      = require 'src.save'

local write_gamestate = require 'src.gamestates.write'

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
    print(
        string.format('Placing %s at (%i, %i).', ATLAS.NAMES[i + 1], x, y)
    )
    level.data[y][x] = {
        id   = i,
        quad = ATLAS:quad(i)
    }
end

local function printAction(t)
    local action = t.action
    print(
        string.format('Placed %s at (%i, %i).',
            ATLAS.NAMES[action.id + 1],
            action.x, action.y)
    )
end

local function printInverse(t)
    local action, inverse = t.action, t.inverse
    print(
        string.format('Replaced %s with %s at (%i, %i).',
            ATLAS.NAMES[action.id + 1],
            ATLAS.NAMES[inverse.id + 1],
            action.x, action.y)
    )
end

local function getFileName(file)
    local file_name = file:match("[^/]*.lua$")
    return file_name:sub(0, #file_name - 4)
end


local Editor = {}

function Editor:init()
    -- Global editor data. If I want it, I get it.
    self.mouse  = { x = 0, y = 0 }    -- Used to calculate camera panning.
    self.pmouse = { x = 0, y = 0 }    -- Mouse coordinates from push translation.
    self.cmouse = { x = 0, y = 0 }    -- Mouse location in tile/cell form.

    self.pressed = false              -- If the left mouse button is pressed.
    self.time    = 0.0                -- How long the left mouse button was pressed.

    self.selected = 0                 -- Selected tile (see ATLAS.TILES)
    self.previous = { x = 0, y = 0 }  -- Previously placed tile (in cell units).
    self.paint    = false             -- If we're 'painting'.

    self.undo = {}                    -- Stack of actions we can undo.
    self.redo = {}                    -- Stack of actions we can redo.

    for y = 1, LEVEL_HEIGHT do
        level.data[y] = {}
        for x = 1, LEVEL_WIDTH do
            level.data[y][x] = {id = TILES.FLOOR, quad = ATLAS:quad(TILES.FLOOR)}
        end
    end

    self.level = level
end

function Editor:enter(previous, level_path)
    love.graphics.setFont(ATLAS.FONT)
    love.graphics.setBackgroundColor(1, 1, 0)

    local level = self.level
    local l     = save.read(level_path)
    for y = 1, #l do
        for x = 1, #l[1] do
            level.data[y][x] = { id = l[y][x], quad = ATLAS:quad(l[y][x]) }
        end
    end

    level.name = getFileName(level_path)
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
        cmouse, selected = self.cmouse, self.selected
        self.previous.x, self.previous.y = cmouse.x, cmouse.y
        self.undo[#self.undo + 1] = {
            action  = { x = cmouse.x, y = cmouse.y, id = selected },
            inverse = { x = cmouse.x, y = cmouse.y, id = level.data[cmouse.y][cmouse.x].id}
        }
        placeTile(cmouse.x, cmouse.y, selected)
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

    msg = ('Play: [ESC]')
    love.graphics.print(msg, 270, 0)

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
    -- Listening for special keyboard combinations.
    if love.keyboard.isDown('lctrl') then
        if     key == 'z' and #self.undo > 0 then  -- [Ctrl+Z] = UNDO
            local recent  = self.undo[#self.undo]  -- Get most recent action.
            local inverse = recent.inverse         -- Get its inverse.
            self.redo[#self.redo + 1] = recent     -- Push it onto redo stack.
            placeTile(inverse.x, inverse.y, inverse.id)

            self.undo[#self.undo] = nil            -- Remove action from undo stack.
        elseif key == 'y' and #self.redo > 0 then  -- [Ctrl+Y] = REDO
            local recent = self.redo[#self.redo]   -- Get most recent undo.
            local action = recent.action           -- Get the original action.
            self.undo[#self.undo + 1] = recent     -- Push it onto undo stack.
            placeTile(action.x, action.y, action.id)

            self.redo[#self.redo] = nil            -- Remove action from redo stack.
        elseif key == 's' then Gamestate.push(write_gamestate) end
    end
end

function Editor:mousepressed(x, y, button)
end

function Editor:mousereleased(x, y, button)
    local cmouse = self.cmouse
    if cmouse.x <= LEVEL_WIDTH and cmouse.y <= LEVEL_HEIGHT and button == 1 and self.time < 0.02 then
        self.previous.x, self.previous.y = cmouse.x, cmouse.y
        self.undo[#self.undo + 1] = {
            action  = { x = cmouse.x, y = cmouse.y, id = self.selected },
            inverse = { x = cmouse.x, y = cmouse.y, id = level.data[cmouse.y][cmouse.x].id}
        }
        placeTile(cmouse.x, cmouse.y, self.selected)
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