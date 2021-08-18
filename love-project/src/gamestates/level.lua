-- General level state.

local SimpleECS = require 'lib.ecs'
local Camera    = require 'lib.hump.camera'
local Map       = require 'src.map'

local MAPS_PATH = 'src/maps'

local level = {}

local Context  = SimpleECS.Context()
Context.camera = Camera.new()

local TILE_SIZE    = 16
local ATLAS        = love.graphics.newImage('assets/atlas.png')
local ATLAS_WIDTH  = ATLAS:getWidth()
local ATLAS_HEIGHT = ATLAS:getHeight()

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

local function generateQuad(index)
    return love.graphics.newQuad(index * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, ATLAS_WIDTH, ATLAS_HEIGHT)
end

local function loadMap(data)
    local map = Map(data)
    for x, y in map:cells() do
        local entity = Context:entity()
        local sprite = generateQuad(map:getValue(x, y))
        Context:give(entity, 'position', (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)
        Context:give(entity, 'sprite', sprite)

        if map:isWall(x, y) then
            Context:give(entity, 'wall')
            Context:give(entity, 'layer', 1)
        elseif map:isBox(x, y) then
            Context:give(entity, 'pushable')
            Context:give(entity, 'layer', 3)
        elseif map:isGoal(x, y) then
            Context:give(entity, 'goal')
            Context:give(entity, 'layer', 2)
        elseif map:isPlayer(x, y) then
            Context:give(entity, 'input', {
                controls = {
                    left  = {'key:left', 'key:a'},
                    right = {'key:right', 'key:d'},
                    up    = {'key:up', 'key:w'},
                    down  = {'key:down', 'key:s'}
                },
                pairs = {
                    move = {'left', 'right', 'up', 'down'}
                }
            })
            Context:give(entity, 'layer', 4)
        end
    end
end

function level:init()
    -- Retrieving all components and systems in single tables.
    local Components = SimpleECS.utils.packDirectory('src/components', {})
    local Systems    = SimpleECS.utils.packDirectory('src/systems', {})

    Context:registerComponents(Components)
    Context:registerSystems(Systems)

    local maps = loadDirectory(MAPS_PATH, {})
    loadMap(maps.sunrise)

    Context.camera:lookAt(4 * 16, 4 * 16)

    Context:createGroup('boxes', 'position', 'pushable')
    Context:createGroup('walls', 'position', 'wall')
    Context:createGroup('goals', 'position', 'goal')

    Context:emit('init')
end

function level:enter(previous, ...)
end

function level:leave()
end

function level:resume()
end

function level:update(delta)
    Context:flush()
    Context:emit('update', delta)
end

function level:draw()
    Context:emit('draw')
end

function level:keypressed(key, scancode, isrepeat)
end

function level:keyreleased(key, scancode)
end

function level:quit()
end

return level