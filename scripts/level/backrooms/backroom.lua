require "scripts.util"
local Class = require "scripts.meta.class"

local Backroom = Class:inherit()

function Backroom:init()

end

--- (Abstract) Generate the map for this backroom.
function Backroom:generate(world_generator)

end

--- (Abstract) Returns whether the backroom should be exited.
function Backroom:can_exit()
    return false
end

function Backroom:on_exit()
end

function Backroom:update(dt)

end

function Backroom:draw()

end

function Backroom:draw_front()
end

return Backroom