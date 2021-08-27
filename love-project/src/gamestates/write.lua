--- Gamestate that exists only when saving a level.

local save      = require 'src.save'
local Gamestate = require 'lib.hump.gamestate'
local ATLAS     = require 'src.atlas'

local EXTENSION = '.lua'
local SAVE_BOX  = {
    x      = 320 / 4, -- (x, y) set from top left corner.
    y      = 180 / 4,
    width  = 320 / 2,
    height = 180 / 2
}
local VALID = { -- Table of valid keyboard keys.
    'a', 'b', 'c', 'd', 'e', 'f', 'g',
    'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u',
    'v', 'w', 'x', 'y', 'z', '1', '2',
    '3', '4', '5', '6', '7', '8', '9',
    '0',
}

local input = ""

local isValid = function(key)
    local res = false
    for i = 1, #VALID do
        if VALID[i] == key then res = true end
    end
    return res
end

local Write = {}

function Write:enter(previous)
    self.from = previous -- Record the previous state.
    input     = previous.level.name
    love.graphics.setFont(ATLAS.FONT)
end

function Write:update(delta)
end

function Write:draw()
    self.from:draw() -- Drawing the previous screen.

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', SAVE_BOX.x, SAVE_BOX.y, SAVE_BOX.width, SAVE_BOX.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', SAVE_BOX.x, SAVE_BOX.y, SAVE_BOX.width, SAVE_BOX.height)

    local msg = 'NAME YOUR LEVEL'
    love.graphics.print(msg, SAVE_BOX.x + 45, SAVE_BOX.y + 10)

    love.graphics.line(SAVE_BOX.x + 10, SAVE_BOX.y + 50,
                       (SAVE_BOX.x + SAVE_BOX.width) - 10,
                       SAVE_BOX.y + 50)

    -- Printing the user input.
    love.graphics.printf(input, SAVE_BOX.x - 40, SAVE_BOX.y + 35,
                         SAVE_BOX.x + SAVE_BOX.width, 'center')
end

function Write:keyreleased(key, scancode)
    if key == 'return' then
        local level = self.from.level
        level.name  = input

        -- Briefly convert the editor level to raw data.
        local data = {}
        local width, height = #level.data[1], #level.data
        for y = 1, height do
            data[y] = {}
            for x = 1, width do
                local bar = level.data[y][x].id
                data[y][x] = level.data[y][x].id
            end
        end

        -- Convert newly constructed data to string.
        data = save.levelToString(data)
        save.ioWrite(data, 'src/maps/' .. input .. EXTENSION)

        Gamestate.pop()
    elseif isValid(key) and #input <= 28 then
        input = input .. key
        print(#input)
    elseif key == 'backspace' then
        input = input:sub(1, -2)
    end
end

return Write