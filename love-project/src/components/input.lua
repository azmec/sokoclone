local baton = require 'lib.baton'

local component = {
    'input',
    function(t) return baton.new(t) end
}

return component