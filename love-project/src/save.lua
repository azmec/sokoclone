--- Functions for reading and writing both custom and original levels.
-- Custom levels are written through the love.filesystem API,
-- while "original" levels are written through the io API.
-- We can generally assume that if we're making an "original" level,
-- we're running the game straight from the main.lua, meaning
-- shouldn't have problems using io. Otherwise, love.filesystem.

--[[
    As an aside, we assume all levels are organized similarly to this:
    {
        { 0, 0, 0, 0, 0, 0, 0, 0 },     0s are interpreted as FLOOR tiles,
        { 0, 0, 0, 0, 0, 0, 0, 0 },     while other values are interpreted
        { 0, 0, 0, 0, 0, 0, 0, 0 },     other varients.
        { 0, 0, 0, 0, 0, 0, 0, 0 },     Every table is a row, and values
        { 0, 0, 0, 0, 0, 0, 0, 0 },     are accessed t[y][x].
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 0 },
    }
]]

local hb    = require 'lib.heartbreak'
local ATLAS = require 'src.atlas'

local TILE_SIZE = ATLAS.TILE_SIZE
local TILES     = ATLAS.TILES

local Save = {}

--- Writes an entire group to the level.
local function groupToTile(Context, group, tile, level)
    for entity in group:entities() do
        local position = Context:getComponent(entity, 'position')
        local cx, cy   = position.x / TILE_SIZE, position.y / TILE_SIZE
        if cx == 0 or cy == 0 then error(
            string.format('expected non-0 integer position (got (%f, %f))',
                           cx, cy),
            hb.getUserErrorLevel()
        )
        end

        level[cy][cx] = tile
    end

    return level
end

--- Creates a Sokoclone level from the given Context.
-- We assume the Context has all necessary components and groups.
Save.contextToLevel = function(Context, width, height)
    hb.ensure(Context, 'table', 1)
    hb.ensure(width, 'number', 2) hb.ensure(height, 'number', 3)

    -- Initialize a level of equivalent width and height.
    local level = {}
    for y = 1, height do
        for x = 1, width do
            level[y][x] = TILES.FLOOR
        end
    end

    -- For all Sokoclone relevant entities, calculate its
    -- cell position and 'write' it into the new level.
    local players     = Context:getGroup('players')
    local boxes       = Context:getGroup('boxes')
    local walls       = Context:getGroup('walls')
    local duplicators = Context:getGroup('duplicators')

    level = groupToTile(Context, players,     TILES.PLAYER,     level)
    level = groupToTile(Context, boxes,       TILES.BOX,        level)
    level = groupToTile(Context, walls,       TILES.WALL,       level)
    level = groupToTile(Context, duplicators, TILES.DUPLICATOR, level)

    return level
end

--- Converts a level into a string.
-- We assume the level is of Sokoclone format.
Save.levelToString = function(level)
    hb.ensure(level, 'table', 1)

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

--- Writes to a .lua file using Lua's built in IO library.
-- Exclusively used when creating prepackaged levels.
Save.ioWrite = function(data, path)
    hb.ensure(data, 'string', 1) hb.ensure(path, 'string', 2)

    local file = io.open('love-project/' .. path, 'w')
    file:write(data) file:flush() file:close()
end

--- Writes to a .lua file using love.filesystem.
-- Exclusively used when making user-created levels.
Save.loveWrite = function(data, path)
    hb.ensure(data, 'string', 1) hb.ensure(path, 'string', 2)

    local success, message = love.filesystem.write(path, data)
    if not success then error(message) end
end

--- Reads a .lua file assuming it's a Sokoclone level.
Save.read = function(path)
    hb.ensure(path, 'string', 1)

    local chunk, message = love.filesystem.read(path)
    if not chunk then error(message) end

    local level = chunk()
    return level
end

return Save