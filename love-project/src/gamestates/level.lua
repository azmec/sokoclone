-- General level state.

local SimpleECS = require 'lib.ecs'
local Camera    = require 'lib.hump.camera'
local Baton     = require 'lib.baton'
local Map       = require 'src.map'

local write = require 'src.write'

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

local FONT        = love.graphics.newFont('assets/bitty.ttf', 16)
local FONT_HEIGHT = FONT:getHeight('A')

function level:init()
    love.graphics.setFont(FONT)

    -- Retrieving all components and systems in single tables.
    local Components = SimpleECS.utils.packDirectory('src/components', {})
    local Systems    = SimpleECS.utils.packDirectory('src/systems', {})

    Context:registerComponents(Components)
    Context:registerSystems(Systems)

    Context.stats = {
        moves  = 0,
        time   = 0,
        pushes = 0,
        level  = ''
    }

    Context:createGroup('boxes', 'position', 'pushable')
    Context:createGroup('walls', 'position', 'wall')
    Context:createGroup('goals', 'position', 'goal')
    Context:createGroup('players', 'position', 'input')
    Context:createGroup('duplicators', 'position', 'duplicator')

    -- Catch-all for all sokoclone entities.
    Context:createGroup('sokoclone', 'position', 'sprite')

    Context:emit('init')
end

function level:enter(previous, level_path)
    Context.map         = write.read(Context, level_path)
    Context.stats.level = level_path

    local width, height = Context.map:getWidth() * TILE_SIZE, Context.map:getHeight() * TILE_SIZE
    Context.camera:lookAt((width / 2) + TILE_SIZE, (height / 2) + TILE_SIZE)

    -- Resetting stats.
    Context.stats = {
        moves  = 0,
        time   = 0,
        pushes = 0,
        level  = ''
    }
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
end

function level:quit()
end

return level