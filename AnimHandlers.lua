--[[
    ■■■■■ AnimHandlers
    ■   ■ Author: Sh1zok
    ■■■■  v0.1.0 All Rights Reserved
]]--

local handlers = {}
local animHandlersAPI = setmetatable({}, {__index = handlers})



function animHandlersAPI:newHandler(handlerName, transformStreams, conditions)
    assert(type(handlerName) == "string", "Invalid argument 1 to function newHandler. Expected string, but got " .. type(handlerName))
    assert(not handlers[handlerName], "Invalid argument 1 to function newHandler. An animations handler with this name already exists")
    assert(type(transformStreams) == "table" or not transformStreams, "Invalid argument 2 to function newHandler. Expected table, but got " .. type(transformStreams))
    assert(type(conditions) == "table" or not conditions, "Invalid argument 3 to function newHandler. Expected table, but got " .. type(conditions))

    transformStreams = transformStreams or {} -- List of animations and functions that could transform some model parts
    conditions = conditions or {}
    local isEnabled = true
    local interface = {
        transformStreams = transformStreams,
        conditions = conditions
    }

    local renderFunction = function()
        for streamName, transformStream in pairs(interface.transformStreams) do
            if interface.conditions[streamName]() then
                if transformStream.play then transformStream:play() end
            else
                if transformStream.stop then transformStream:stop() end
            end
        end
    end


    -- Enables the animation handler
    function interface:enable()
        events.render:register(renderFunction, "animationsHandler." .. handlerName)
        return self -- Returns self for chaining
    end

    -- Disables the animation handler
    function interface:disable()
        events.render:remove("animationsHandler." .. handlerName)
        for _, transformStream in pairs(interface.transformStreams) do
            if transformStream.stop then transformStream:stop() end
        end

        return self -- Returns self for chaining
    end

    -- Sets the name of the animation handler
    function interface:setName(newName)
        assert(type(newName) == "string", "Invalid argument to function setName. Expected string, but got " .. type(newName))
        assert(not handlers[newName], "Invalid argument to function setName. An animations handler with this name already exists")

        local oldname = handlerName
        handlerName = newName
        handlers[oldname], handlers[handlerName] = nil, interface

        if isEnabled then
            events.render:remove("animationsHandler." .. oldname)
            events.render:register(renderFunction, "animationsHandler." .. handlerName)
        end

        return self -- Returns self for chaining
    end

    -- Gets the name of the animation handler
    function interface:getName() return handlerName end

    -- Returns true if handler is enabled
    function interface:isEnabled() return isEnabled end

    -- Erases the animation handler
    function interface:remove()
        interface:disable()
        handlers[handlerName], isEnabled, transformStreams, conditions, interface = nil, nil, nil, nil, nil

        return nil
    end



    interface = setmetatable(interface, {__index = transformStreams, __newindex = function() error("Cannot assign new method/field to an animations handler", 2) end})
    handlers[handlerName] = interface

    interface:enable()
    return interface
end

function animHandlersAPI:getHandlers()
    local handlersList = {}
    for handlerName, handlerInterface in pairs(handlers) do handlersList[handlerName] = handlerInterface end
    return handlersList
end

function animHandlersAPI:getEnabled()
    local enabledHandlers = {}

    for handlerName, handlerInterface in pairs(handlers) do
        if handlerInterface:isEnabled() then enabledHandlers[handlerName] = handlerInterface end
    end

    return enabledHandlers
end

function animHandlersAPI:disableAll()
    for _, handler in pairs(handlers) do handler:disable() end
end



return animHandlersAPI