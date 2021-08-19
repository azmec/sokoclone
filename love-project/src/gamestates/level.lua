-- General level state.

local SimpleECS = require 'lib.ecs'
local Camera    = require 'lib.hump.camera'
local Baton     = require 'lib.baton'
local Map       = require 'src.map'

local write = require 'src.write'

local MAPS_PATH = 'src/maps'

local level = {}

local Context  = SimpleECS.Context()
Context.camera = Camera.new()
Context.input  = Baton.new({
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

local TILE_SIZE    = 16
local ATLAS        = love.graphics.newImage('assets/atlas.png')
local ATLAS_WIDTH  = ATLAS:getWidth()
local ATLAS_HEIGHT = ATLAS:getHeight()

local FONT        = love.graphics.newFont('assets/bitty.ttf', 16)
local FONT_HEIGHT = FONT:getHeight('A')

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
        Context:give(entity, 'position', x * TILE_SIZE, y * TILE_SIZE)
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
            Context:give(entity, 'layer', 4)
            Context:give(entity, 'input')
        elseif map:isDuplicator(x, y) then
            Context:give(entity, 'duplicator')
            Context:give(entity, 'layer', 2)
        end
    end

    return map
end

function level:init()
    love.graphics.setFont(FONT)

    -- Retrieving all components and systems in single tables.
    local Components = SimpleECS.utils.packDirectory('src/components', {})
    local Systems    = SimpleECS.utils.packDirectory('src/systems', {})

    Context:registerComponents(Components)
    Context:registerSystems(Systems)

    local maps  = loadDirectory(MAPS_PATH, {})
    Context.map = loadMap(maps.sunrise)

    local width, height = Context.map:getWidth() * TILE_SIZE, Context.map:getHeight() * TILE_SIZE
    Context.camera:lookAt(width / 2, height / 2)

    Context.stats = {
        moves  = 0,
        time   = 0,
        pushes = 0,
        level  = 0
    }

    Context:createGroup('boxes', 'position', 'pushable')
    Context:createGroup('walls', 'position', 'wall')
    Context:createGroup('goals', 'position', 'goal')
    Context:createGroup('players', 'position', 'input')
    Context:createGroup('duplicators', 'position', 'duplicator')

    Context:emit('init')
end

function level:enter(previous, ...)
end

function level:leave()
end

function level:resume()
end

function level:update(delta)
    Context.input:update(delta)
    Context.stats.time = Context.stats.time + delta

    Context:flush()
    Context:emit('update', delta)
end

function level:draw()
    Context:emit('draw')

    local msg = "Level: " .. tostring(Context.stats.level)
    love.graphics.print(msg, 10, 10)

    msg = "Moves: " .. tostring(Context.stats.moves)
    love.graphics.print(msg, 10, 10 + FONT_HEIGHT / 2)

    msg = "Pushes: " .. tostring(Context.stats.pushes)
    love.graphics.print(msg, 10, 10 + FONT_HEIGHT)

    msg = "Time: " .. tostring(math.floor(Context.stats.time))
    love.graphics.print(msg, 10, 10 + FONT_HEIGHT * 1.5)
end

function level:keypressed(key, scancode, isrepeat)
end

function level:keyreleased(key, scancode)
    if key == 'space' then write.serialize(Context) end
end

function level:quit()
end

return level