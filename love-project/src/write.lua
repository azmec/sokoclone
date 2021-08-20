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

local function resize(map, out_of_bounds)
    local width, height = #map[1], #map
    local mx, my        = width, height

    -- Find the new boundaries of the map.
    for i = 1, #out_of_bounds do
        local point = out_of_bounds[i]
        -- We'll assume the boundaries of a map are marked by walls.
        if point[3] ~= TILES.WALLS then
            if point[1] > mx then mx = point[1] end
            if point[2] > my then my = point[2] end
        end
    end

    if mx == width and my == height then return map -- No dimensional change.
    elseif mx > width or my > height then           -- Level is bigger.
    else                                            -- Level must be smaller.

    -- Populate a new map with those boundaries.
    local new = {}
    for y = 1, my do
        new[y] = {}
        for x = 1, mx do
            new[y][x] = 0
        end
    end

    -- 'Copy' the given map into the new one.
    for y = 1, height do
        for x = 1, width do
            new[y][x] = map[y][x]
        end
    end

    -- 'Copy' out of bound tiles into the new one.
    for i = 1, #out_of_bounds do
        local point = out_of_bounds[i]
        local x, y  = point[1], point[2]
        local tile  = point[3]
        new[y][x]   = tile
    end

    -- Cull floor tiles that are beyond the furthest known walls.
    -- These are inaccessible to the player anyway, and they'd interfere
    -- with interpreting the level's width and height.
    -- It's possible for the *initial* known width and height to be beyond
    -- the known walls, hence the need for this culling.

    --[[
        There's three cases for a level resize:
            A. The level is *larger* than it previously was.
            B. The level is *smaller* than it previously was.
            C. The level remained the same.
        In case C, we just exit and return exactly what we were given.
        In A and B, though, we need to some work.

        For A, it's as simple as finding the furthest *wall tile* and
        considering that to be the bottomright corner of the level.

        For B, we do the same thing, but instead `nil` array indices.
    ]]
    return new
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
write.resize    = resize

return write