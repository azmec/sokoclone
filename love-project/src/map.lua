--- Map container to simplify queries and such.

local hb = require 'lib.heartbreak'

local WALL   = 0
local PLAYER = 1
local FLOOR  = 2
local BOX    = 3
local GOAL   = 4

local Map = {}
Map.__mt = { __index = Map }

Map.new = function(data)
    return setmetatable({
        data   = data,
        height = #data,
        width  = #data[1]
    }, Map.__mt)
end

function Map:valueAt(x, y)
    hb.truthy(x <= self.width, 'x component beyond width of map')
    hb.truthy(y <= self.height, 'y component beyond height of map')

    return self.data[y][x]
end

function Map:isWall(x, y)  return self.data[y][x] == WALL  end
function Map:isEmpty(x, y) return self.data[y][x] == FLOOR end
function Map:isBox(x, y)   return self.data[y][x] == BOX   end
function Map:isGoal(x, y)  return self.data[y][x] == GOAL  end

function Map:set(x, y, i) self.data[y][x] = i end

function Map:cells()
    local x, y = 0, 1

    return function()
        if x >= self.width then x = 0 y = y + 1 end
        if y <= self.height then
            x = x + 1
            return x, y
        end
    end
end

return setmetatable(Map, {
    __call = function(_, ...)
        return Map.new(...)
    end
})