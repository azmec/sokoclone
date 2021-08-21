--- Error handling for easier development.
-- Ripped from nata so far.
-- Titled 'heartbreak' for "breaking LÖVE."

local heartbreak = {}

local userErrorLevel = function()
    local source, level = debug.getinfo(1).source, 1
    while debug.getinfo(level).source == source do level = level + 1 end
    return level - 1
end

local userFunction = function() return debug.getinfo(userErrorLevel() - 1).name end

heartbreak.truthy = function(condition, message)
    if condition then return end
    error(message, userErrorLevel())
end

heartbreak.ensure = function(argument, expected, index)
    if type(argument) == expected then return end

    error(
        string.format(
            'bad argument to #%i to "%s" (expected %s, got %s)',
            index,
            userFunction(),
            desired,
            type(argument)
        ),
        userErrorLevel()
    )
end

heartbreak.getUserErrorLevel = getUserErrorLevel

return heartbreak