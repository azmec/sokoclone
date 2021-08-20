--- Writes a Context's level data to a 2D Array.
-- If you're looking at this from the outside:
-- it's super specific to the structure of this game.
-- Don't take it as gospel for anything.

local Map   = require 'src.map'
local ATLAS = require 'src.atlas'

local TILES     = ATLAS.TILES
local TILE_SIZE = ATLAS.TILE_SIZE

local write = {}

local function levelToString(level)
    local width, height = #level[1], #level

    local data = "return {\n"
    for y = 1, height do
        data = data .. "    { "
        for x = 1, width do
            data = data .. string.format(" %i,", level[y][x])
        end
        data = data .. " },\n"
    end

    data = data .. "}"

    return data
end

--- Writes a Context's Sokoclone level data to the given file path.
-- Touches a new file if it doesn't exist already.
write.serialize = function(Context, path)
    -- Get all Sokoclone groups.
    local players     = Context:getGroup('players')
    local boxes       = Context:getGroup('boxes')
    local walls       = Context:getGroup('walls')
    local duplicators = Context:getGroup('duplicators')

    -- Find the *current* dimensions of the map.
    local map           = Context.map
    local width, height = map:getWidth(), map:getHeight()


    -- Populate a level of identical size with floor tiles.
    local level = {}
    for y = 1, height do
        level[y] = {}
        for x = 1, width do
            level[y][x] = 0
        end
    end

    -- For every Sokoclone entity in the Context, find its cell
    -- position and "write" it into the level array with the correct ID.
    for entity in players:entities() do
        local position = Context:getComponent(entity, 'position')
        local cx, cy   = position.x / TILE_SIZE, position.y / TILE_SIZE

        if cx == 0 or cy == 0 then error('Position is 0.')
        else level[cy][cx] = TILES.PLAYER end
    end
    for entity in boxes:entities() do
        local position = Context:getComponent(entity, 'position')
        local cx, cy   = position.x / TILE_SIZE, position.y / TILE_SIZE

        if cx == 0 or cy == 0 then error('Position is 0.')
        else level[cy][cx] = TILES.BOX end
    end
    for entity in walls:entities() do
        local position = Context:getComponent(entity, 'position')
        local cx, cy   = position.x / TILE_SIZE, position.y / TILE_SIZE

        if cx == 0 or cy == 0 then error('Position is 0.')
        else level[cy][cx] = TILES.WALL end
    end
    for entity in duplicators:entities() do
        local position = Context:getComponent(entity, 'position')
        local cx, cy   = position.x / TILE_SIZE, position.y / TILE_SIZE

        if cx == 0 or cy == 0 then error('Position is 0.')
        else level[cy][cx] = TILES.DUPLICATOR end
    end

    -- Take the level table and represent it as a string.
    local data = levelToString(level)

    -- Write it to wherever the identity is set.
    local success, message = love.filesystem.write('test.lua', data)
    if not success then error(message) end

    -- Return both the level data and string data in a table.
    return {level = level, data = data}
end

--- Reads and loads a Sokoclone level into the Context.
-- Assumes the Context has all necessary components.
write.read = function(Context, path)
    -- Get all Sokoclone entities and destory them.
    for entity in Context:getGroup('sokoclone'):entities() do Context:destroy(entity) end

    -- Read level and translate data into Context.
    local level, message = love.filesystem.load(path)
    if not level then error(message) end

    local map = Map(level())
    for x, y in map:cells() do
        local entity = Context:entity()
        local sprite = ATLAS:quad(map:getValue(x, y))
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

write.tostring = levelToString

return write