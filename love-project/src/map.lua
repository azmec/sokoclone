--- Map container to simplify queries and such.

local WALL       = 2
local PLAYER     = 1
local FLOOR      = 0
local BOX        = 3
local GOAL       = 4
local DUPLICATOR = 5

local Map = {}
Map.__mt = { __index = Map }

Map.new = function(data)
    return setmetatable({
        data   = data,
        height = #data,
        width  = #data[1]
    }, Map.__mt)
end

-- Easy getters and checkers.
function Map:getValue(x, y)     return self.data[y][x] end
function Map:isWall(x, y)       return self.data[y][x] == WALL   end
function Map:isPlayer(x, y)     return self.data[y][x] == PLAYER end
function Map:isFloor(x, y)      return self.data[y][x] == FLOOR  end
function Map:isBox(x, y)        return self.data[y][x] == BOX    end
function Map:isGoal(x, y)       return self.data[y][x] == GOAL   end
function Map:isDuplicator(x, y) return self.data[y][x] == DUPLICATOR end

-- Easy setters.
function Map:setValue(x, y, i)   self.data[y][x] = i          end
function Map:setWall(x, y)       self.data[y][x] = WALL       end
function Map:setPlayer(x, y)     self.data[y][x] = PLAYER     end
function Map:setFloor(x, y)      self.data[y][x] = FLOOR      end
function Map:setBox(x, y)        self.data[y][x] = BOX        end
function Map:setGoal(x, y)       self.data[y][x] = GOAL       end
function Map:setDuplicator(x, y) self.data[y][x] = DUPLICATOR end

function Map:getWidth()  return self.width  end
function Map:getHeight() return self.height end

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