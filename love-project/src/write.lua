--- Writes a Context's level data to a 2D Array.
-- If you're looking at this from the outside:
-- it's super specific to the structure of this game.
-- Don't take it as gospel for anything.

local write = {}

local TILE_SIZE  = 16

-- IDs of tiles.
local WALL       = 2
local PLAYER     = 1
local FLOOR      = 0
local BOX        = 3
local GOAL       = 4
local DUPLICATOR = 5

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

        if cx == 0 or cy == 0 then error('You fucked up. Have fun fixing it.')
        else level[cy][cx] = PLAYER end
    end
    for entity in boxes:entities() do
        local position = Context:getComponent(entity, 'position')
        local cx, cy   = position.x / TILE_SIZE, position.y / TILE_SIZE

        if cx == 0 or cy == 0 then error('You fucked up. Have fun fixing it.')
        else level[cy][cx] = BOX end
    end
    for entity in walls:entities() do
        local position = Context:getComponent(entity, 'position')
        local cx, cy   = position.x / TILE_SIZE, position.y / TILE_SIZE

        if cx == 0 or cy == 0 then error('You fucked up. Have fun fixing it.')
        else level[cy][cx] = WALL end
    end
    for entity in duplicators:entities() do
        local position = Context:getComponent(entity, 'position')
        local cx, cy   = position.x / TILE_SIZE, position.y / TILE_SIZE

        if cx == 0 or cy == 0 then error('You fucked up. Have fun fixing it.')
        else level[cy][cx] = DUPLICATOR end
    end

    -- Take the level table and represent it as a string.
    local data = "{\n"
    for y = 1, height do
        data = data .. "    { "
        for x = 1, width do
            data = data .. string.format(" %i,", level[y][x])
        end
        data = data .. " },\n"
    end

    data = data .. "}"

    -- Write it to wherever the identity is set.
    local success, message = love.filesystem.write('test.lua', data)
    if not success then error(message) end

    -- Return both the level data and string data in a table.
    return {level = level, data = data}
end

--- Reads and loads a Sokoclone level into the Context.
-- Assumes the Context has all necessary components.
write.read = function(Context, level)
end

return write