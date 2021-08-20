--- Easy require for sprite and font rendering.
-- It was getting messy.

local image = love.graphics.newImage('assets/atlas.png')
local font  = love.graphics.newFont('assets/bitty.ttf', 16)

local keys = function(t)
    local res = {}
    for k, v in pairs(t) do
        res[v + 1] = k
    end
    return res
end

local ATLAS = {
    TILE_SIZE   = 16,
    IMAGE       = image,
    WIDTH       = image:getWidth(),
    HEIGHT      = image:getHeight(),
    FONT        = font,
    FONT_HEIGHT = font:getHeight('A')
}

ATLAS.TILES = {
    FLOOR      = 0,
    PLAYER     = 1,
    WALL       = 2,
    BOX        = 3,
    GOAL       = 4,
    DUPLICATOR = 5
}

ATLAS.NAMES = keys(ATLAS.TILES)

--- Returns a new quad representing some sprite in the atlas.
ATLAS.quad = function(self, index)
    local TILE_SIZE = self.TILE_SIZE
    return love.graphics.newQuad(index * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE,
                                 self.WIDTH, self.HEIGHT)
end

return ATLAS