local SimpleECS = require 'lib.ecs'

local controllerSystem = SimpleECS.System('input')
local Context

function controllerSystem:init()
    Context = self.context
end

function controllerSystem:update(delta)
    for entity in self.pool:elements() do
        Context:getComponent(entity, 'input'):update(delta)
    end
end

return controllerSystem