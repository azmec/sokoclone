--- Simple, "proper" entity component system inspired by Concord, Nata, and others.
-- Forgoes entities as objects entirely, basking in the ancient sunlight of data-oriented
-- programming, leaving the object-oriented drivel to decay and rot for enternity.
-- Also, just another way of doing ECS. If your entities are interfacing a lot with other
-- libraries, I highly recommend Concord to avoid the work of integrating SimpleECS with
-- those libraries.
-- @author aldats
-- @module SimpleECS
-- @copyright 2021
-- @license MIT
-- @release 0.8.0


local bit             = require 'bit'
local band, bor, bnot = bit.band, bit.bor, bit.bnot
local lshift, rshift  = bit.lshift, bit.rshift

local floor, min = math.floor, math.min

local SimpleECS = {}

-----------------------------------
-- Utility Structures and Functions
-----------------------------------

-- @section Error Handling

--- Returns the error level needed for the error to appear.
-- Credit to @tesselode for this function. Otherwise, user errors
-- would report incorrectly.
-- @return number
local userErrorLevel = function()
    local source, level = debug.getinfo(1).source, 1
    while debug.getinfo(level).source == source do level = level + 1 end
    return level - 1
end

--- Returns the name of the function that the user called to cause an error.
-- Credit to @tesselode for this one too; Helps users recognize what they did
-- that caused the error.
-- @return string
local userFunction = function() return debug.getinfo(userErrorLevel() - 1).name end

--- Catch all condition check.
-- Reports at what level the error occured and the user function
-- that caused it.
-- @param condition Some boolean expression to check for truthy.
-- @param message string Text to emit on error.
local ensure = function(condition, message)
    if condition then return end
    error(message, userErrorLevel())
end

--- Checks the type of the given argument against the desired type.
-- @param argument Argument to type check.
-- @param desired The desired type.
-- @param index Index of the argument in function stub.
local checkType = function(argument, desired, index)
    if type(argument) == desired then return end

    error(
        string.format(
            'bad argument #%i to "%s" (expected %s, got %s)',
            index,
            userFunction(),
            desired,
            type(argument)
        ),
        userErrorLevel()
    )
end

-- @section Table Manipulation

--- Packs the given arguments into a table and returns it.
-- @param ... - Data to pack.
-- @return table
local pack = function(...) return { ... } end

-- @section Path Loading

--- Requires files and loads them into a table.
-- Accepts a path to a directory, such as 'src/systems' or 'src/components'
-- It must use forward slashes.
-- @param path - Path to directory.
-- @param t - Table to load files into.
-- @return table - Numerically indexed table of loaded files.
local packDirectory = function(path, t)
    if not t then t = {} end

    checkType(path, 'string', 1)
    checkType(t, 'table', 2)

    local info = love.filesystem.getInfo(path)
    if info == nil or info.type ~= 'directory' then
        error("bad argument #1 to 'packDirectory' (path '" .. path .. "' not found.)", 2)
    end

    local files = love.filesystem.getDirectoryItems(path)

    for _, file in ipairs(files) do
        local name      = file:sub(1, #file - 4) -- removing '.lua'
        local file_path = path .. '.' .. name
        local value     = require(file_path)

        t[#t + 1] = value
    end

    return t
end

-- @section Signature Manipulation

-- Amount of bits in a number. Change this as needed, it won't break anything.
local NUM_BITS = 32

--- Sets the ith bit in the given number.
-- @param x number
-- @param i number Bit to set.
-- @return number
local function setBit(x, i) return bor(x, lshift(1, i)) end

--- Clears the ith bit in the given number.
-- @param x number
-- @param i number Bit to clear.
-- @return number
local function clearBit(x, i) return band(x, bnot(lshift(1, i))) end

--- Checks if the ith bit is set in the given number.
-- @param x number
-- @param i number Bit to check.
-- @return bool
local function isSet(x, i) return band(rshift(x, i), 1) ~= 0 end

--- Sets the component within the signature.
-- @param t table Signature to mutate.
-- @param i number ID of component to set.
local function setComponent(t, i)
    local index = floor(i / NUM_BITS) + 1
    if index > #t then
        for i = #t + 1, index do t[i] = 0 end
    end

    i = i % NUM_BITS
    t[index] = setBit(t[index], i)
end

--- Clears the component within the signature.
-- @param t table Signature to mutate.
-- @param i number ID of component to clear.
local function clearComponent(t, i)
    local index = floor(i / NUM_BITS) + 1
    if index > #t then return end

    i = i % NUM_BITS
    t[index] = clearBit(t[index], i)
end

--- Checks if a signature has the component.
-- @param t table Signature to check.
-- @param i number ID of component to check.
local function hasComponent(t, i)
    local index = floor(i / NUM_BITS) + 1
    if index > #t then return false end

    i = i % NUM_BITS
    return isSet(t[index], i)
end

--- Checks if a bitset is a subset of another bitset.
-- @param a table Bitset to use as base.
-- @param b table Bitset to check for subset status.
-- @return bool
local function isSubset(a, b)
    local count = min(#a, #b)
    if #a > count then
        for i = count, #a do
            if a[i] ~= 0 then return false end
        end
    end

    for i = 1, count do
        local byte = a[i]
        if band(byte, b[i]) ~= byte then return false end
    end

    return true
end

--- Sets multiple components within the signature.
-- @param t table Signatue to mutate.
-- @param ... number Components to set.
local function setComponents(t, ...)
    local components = pack(...)
    for i = 1, #components do setComponent(t, components[i]) end
end

-- @section SparseSet

local SparseSet = {}
SparseSet.__mt = { __index = SparseSet }

--- Returns a new SparseSet.
-- A sparse set allows for rapid iteration of array indices by packing them
-- internally into a dense table.
-- @return SparseSet
SparseSet.new = function()
    return setmetatable({
        sparse      = {}, -- Sparse array. Cringe cache-allocation.
        dense       = {}, -- Packed array. Based cache-allocation.
    }, SparseSet.__mt)
end

--- Checks if the set contains the given integer.
-- @param element number Integer to check for.
-- @return bool
function SparseSet:contains(element)
    local sparse = self.sparse
    return sparse[element] ~= nil
end

--- Inserts the integer into the set.
-- @param element number Integer to insert.
function SparseSet:insert(element)
    if self:contains(element) then return end -- Already in set; don't care.

    local index = #self.dense + 1
    self.dense[index]    = element
    self.sparse[element] = index
end

--- Removes an integer from the set.
-- @param element number Integer to remove.
function SparseSet:remove(element)
    if not self:contains(element) then return false end -- Element not present; do nothing.
    local dense, sparse = self.dense, self.sparse
    local tail = dense[#dense]
    dense[sparse[element]] = tail
    sparse[tail] = sparse[element]

    dense[#dense]   = nil
    sparse[element] = nil

    return true
end

--- Returns an iterator through the elements of the sparse set.
-- @return function
function SparseSet:elements()
    local i, n = 0, #self.dense
    return function()
        i = i + 1
        if i <= n then return self.dense[i] end
    end
end

--- Returns the size of the set.
-- @return number
function SparseSet:size() return #self.dense end

--- Clears the sparse set.
function SparseSet:clear() self.dense = {} self.sparse = {} end

-- @section Stack

local Stack = {}
Stack.__mt = { __index = Stack }

--- Returns a new Stack.
-- @return Stack
Stack.new = function()
    return setmetatable({
        store = {},
        __size  = 0
    }, Stack.__mt)

end

--- Pushes an element onto the top of the stack.
-- @param element Variant Element to push.
function Stack:push(element)
    local index = self.__size + 1
    self.store[index] = element
    self.__size         = index
end

--- Pops and returns an element from the top of the stack.
-- @return Variant
function Stack:pop()
    local index = self.__size
    local res   = self.store[index]
    self.store[index] = nil
    self.__size         = index - 1
    return res
end

--- Returns the size of the stack.
-- @return number The size of the stack.
function Stack:size() return self.__size end

---------------------------------------
-- Core Structures and Implementations.
---------------------------------------

-- @section EntityIndex

local EntityIndex = {}
EntityIndex.__mt = { __index = EntityIndex }

--- Returns a new EntityIndex.
-- Maintains a SparseSet of entity IDs and a stack of destroyed entity IDs.
-- @return EntityIndex
EntityIndex.new = function()
    return setmetatable({
        entities  = SparseSet.new(),
        destroyed = Stack.new(),
        alive     = 0
    }, EntityIndex.__mt)
end

function EntityIndex:isAlive(entity)
    return self.entities:contains(entity)
end

function EntityIndex:createEntity()
    local id = nil
    if self.destroyed:size() > 0 then id = self.destroyed:pop()
    else id = self.alive + 1 end

    self.entities:insert(id)
    self.alive = self.alive + 1

    return id
end

function EntityIndex:destroyEntity(entity)
    if self.alive <= 0 then return end -- No entities to destroy.
    if not self.entities:contains(entity) then return end -- Already dead.

    self.entities:remove(entity)
    self.destroyed:push(entity)

    self.alive = self.alive - 1
end

-- @section ComponentArray

local ComponentArray = {}
ComponentArray.__mt = { __index = ComponentArray }

--- Returns a new ComponentArray.
-- Maintains an internal array of component data
-- in which entity IDs are indices.
-- @retrun ComponentArray
ComponentArray.new = function(constructor)
    return setmetatable({
        constructor = constructor,
        entities = {},
    }, ComponentArray.__mt)
end

--- Constructs a new component for the given entity.
-- @param entity number ID in which to create the component.
-- @param ... Construction arguments for the component.
function ComponentArray:construct(entity, ...)
    if self.entities[entity] then error('Entity already has this component!') end
    self.entities[entity] = self.constructor(...)
end

--- Returns a reference to the component of the given entity.
-- @param entity number Entity possessing desired component data.
-- @return Variant Component data.
function ComponentArray:peak(entity)
    if not self.entities[entity] then error("Entity doesn't have this component!") end
    return self.entities[entity]
end

--- Destroys the component of the given entity.
-- @param entity number ID to render nil.
function ComponentArray:destroy(entity)
    self.entities[entity] = nil
end

--- Checks if the ComponentArray has the entity.
-- @param entity number ID of the entity.
-- @return bool
function ComponentArray:has(entity) return self.entities[entity] ~= nil end

local Filter = {}
Filter.__mt = { __index = Filter }

--- Returns a new Filter.
-- Interface to quickly generate and match signatures based on component data.
-- @param components table An array of component IDs.
-- @param ... string Components to filter for.
-- @see Context:getComponentList
-- @return Filter
Filter.new = function(components, ...)
    local required, ids = pack(...), {}
    for i = 1, #required do
        local id = components[required[i]]
        if id == nil then error('Component not registered!')
        else ids[i] = id end
    end

    local signature = {}
    setComponents(signature, unpack(ids))

    return setmetatable({
        signature = signature
    }, Filter.__mt)
end

--- Checks if the given signature matches that of the Filter.
-- @param other table Signature to check.
-- @return bool
function Filter:match(other) return isSubset(self.signature, other) end

-- @section System

local System = {}
System.__mt = { __index = System }

--- Constructs a new System.
-- Collection of entities whose signatures match that of the System's.
-- @return System
System.new = function(...)
    return setmetatable({
        required = pack(...),
        pool     = SparseSet.new(),

        -- Filled in by Context on registration.
        filter   = nil,
        context  = nil
    }, System.__mt)
end

--- Iterator which returns the ID of each entity.
-- @return function
function System:entities()
    local pool    = self.pool
    local i, size = 0, pool:size()
    return function()
        i = i + 1
        if i <= size then return pool.dense[i] end
    end
end

--- Evaluate if the entity qualifies for the system and take relevant action.
-- @param entity number Entity to evaluate.
-- @param signature table Signature of the entity.
function System:evaluate(entity, signature)
    local filter, pool = self.filter, self.pool
    local contains = pool:contains(entity)
    local matches  = filter:match(signature)

    if not matches and contains then
        pool:remove(entity)
        self:onEntityRemoved(entity)
    elseif matches and not contains then
        pool:insert(entity)
        self:onEntityAdded(entity)
    end
end

--- Removes the entity from the system.
-- @param entity number Entity to remove.
function System:remove(entity) self.pool:remove(entity) end

--- Returns the names of the required components in a table.
-- @return table Array of the required components.
function System:getRequired() return self.required end

--- Callback for entity addition.
-- @param entity number The ID of the added entity.
function System:onEntityAdded(entity) end

--- Callback for entity removal.
-- @param entity number The ID of the removed entity.
function System:onEntityRemoved(entity) end

-- @section Context

local Context = {}
Context.__mt = { __index = Context }

--- Returns a new Context.
-- Coordinates an internal collection of entities, components, and systems.
-- @return Context
Context.new = function()
    return setmetatable({
        componentSets   = {},                -- Array of ComponentSets, with component IDs as indices.
        components      = {},                -- Table of componentIDs, with component names as keys.
        signatures      = {},                -- Array of signatures, with entity IDs as indices.
        systems         = {},                -- Array of Systems.
        entityIndex     = EntityIndex.new(), -- All living entities and past entities.
        dirty           = SparseSet.new(),   -- Set of entities who we have marked dirty.
        toDelete        = SparseSet.new(),   -- Entities queued to be deleted.
        component_count = 0                  -- Count of registered components.
    }, Context.__mt)
end

local addComponent = function(self, component)
    local name, constructor = component[1], component[2]
    ensure(
        not self.components[name],
        "Component '" .. name .. "' is already registred with the Context!"
    )

    local id = self.component_count + 1
    self.components[name]  = id
    self.componentSets[id] = ComponentArray.new(constructor)
    self.component_count   = id
end

local addSystem = function(self, system)
    system.context = self
    system.filter  = Filter.new(self.components, unpack(system.required))
    for entity in self:entities() do
        system:evaluate(entity, self.signatures[entity])
    end

    self.systems[#self.systems + 1] = system
end

local getComponent = function(self, entity, component)
    return self.componentSets[self.components[component]]:peak(entity)
end

--- Registers a component.
-- A Component is a table with length of 2, such that t[1] is the
-- name of the component and t[2] a function that returns component data.
-- @param component table Component to register.
function Context:registerComponent(component)
    checkType(component, 'table', 1)
    addComponent(self, component)
end

--- Registers multiple components at once.
-- @param t table Array of components to register.
function Context:registerComponents(t)
    checkType(t, 'table', 1)
    print(#t)
    for i = 1, #t do addComponent(self, t[i]) end
end

--- Registers a system.
-- @param system System System to register.
function Context:registerSystem(system)
    checkType(system, 'table', 1)
    addSystem(self, system)
end

--- Registers multiple systems at once.
-- @param t table Array of systems to register.
function Context:registerSystems(t)
    checkType(t, 'table', 1)
    for i = 1, #t do addSystem(self, t[i]) end
end

--- Evaluates and flushes changes to entities.
-- Adds and removes entities from existing systems or the Context altogether.
function Context:flush()
    -- Check relevant lists. If they're empty, nothing to flush.
    if self.dirty:size() == 0 and self.toDelete:size() == 0 then return end
    local dirty, to_add, toDelete  = self.dirty, self.to_add, self.toDelete
    local componentSets, components = self.componentSets, components
    local systems, signatures       = self.systems, self.signatures

    -- Process entities who have been removed from the Context.
    for entity in toDelete:elements() do
        for i = 1, #systems do systems[i]:remove(entity) end
        for i = 1, #componentSets do componentSets[i]:destroy(entity) end
        signatures[entity] = nil

        self.entityIndex:destroyEntity(entity)
        self:onEntityRemoved(entity)
    end
    toDelete:clear()

    -- Check for entities whose components have been given or taken.
    for entity in dirty:elements() do
        local signature = signatures[entity]
        for i = 1, #systems do systems[i]:evaluate(entity, signature) end
    end
    dirty:clear()
end

--- Registers and returns the ID of the entity.
-- @return number ID of the entity.
function Context:entity()
    local id = self.entityIndex:createEntity()
    self.signatures[id] = {0}
    self:onEntityAdded(id)

    return id
end

--- Destroys the entity.
-- The entity isn't destroyed until the next `:flush()` call.
-- @param entity number Entity to destroy.
function Context:destroy(entity)
    ensure(self.entityIndex:isAlive(entity), 'Entity is not alive!')
    self.toDelete:insert(entity)
end

--- Gives the component to the entity.
-- @param entity number ID of the entity.
-- @param component string Component to give.
-- @param ... Constructor arguments.
function Context:give(entity, component, ...)
    local alive, componentArray = self.entityIndex:isAlive(entity), self.componentSets[self.components[component]]
    ensure(alive, 'Entity is not alive!')
    ensure(componentArray, 'Component is not registered with the Context!')

    local component_id = self.components[component]
    local signature    = self.signatures[entity]
    signature = setComponent(signature, component_id)

    self.dirty:insert(entity)
    componentArray:construct(entity, ...)
end

--- Removes the component from the entity.
-- @param entity number ID of the entity.
-- @param component string Component to remove.
function Context:remove(entity, component)
    local alive, componentArray = self.entityIndex:isAlive(entity), self.componentSets[self.components[component]]
    ensure(alive, 'Entity is not alive!')
    ensure(componentArray, 'Component is not registered with the Context!')

    local component_id = self.components[component]
    local signature = self.signatures[entity]
    signature = clearComponent(signature, component_id)

    self.dirty:insert(entity)
    componentArray:destroy(entity)
end


--- Shortcut to creating and registering a component.
-- @param name string Name of the component.
-- @pram constructor function Function that returns component data.
function Context:createComponent(name, constructor)
    checkType(name, 'string', 1) checkType(constructor, 'function', 2)
    ensure(not self.componentSets[name], 'Component has already been registered with the Context!')
    self:registerComponent({name, constructor})
end

--- Emits the given event.
-- For every system that has the event, the funtion will be called.
-- @param string event The event to emit.
-- @param ... Additional arguments to pass to event functions.
function Context:emit(event, ...)
    ensure(event, 'Event cannot be nil!')
    checkType(event, 'string', 1)

    for i = 1, #self.systems do
        local system = self.systems[i]
        if system[event] and type(system[event] == 'function') then
            system[event](system, ...)
        end
    end
end

--- Clears _everything_ in the Context, effectively making it a new instance.
function Context:clear()
    self.componentSets   = {}
    self.components      = {}
    self.component_count = 0

    self.entityIndex = EntityIndex.new()
    self.toDelte     = SparseSet.new()
    self.dirty       = SparseSet.new()

    self.systems    = {}
    self.signatures = {}
end

--- Callback for when an entity is added to the Context.
-- @param entity number The ID of the entity that was added.
function Context:onEntityAdded(entity) end

--- Callback for when an entity is removed from the Context.
-- @param entity number The ID of the entity that was removed.
function Context:onEntityRemoved(entity) end

-------------------------
--- Querying the Context.
-------------------------

--- Returns true/false if the entity is alive.
-- @param entity number ID of the entity to check.
-- @return bool True if entity is alive, false otherwise.
function Context:isAlive(entity) return self.entityIndex:isAlive(entity) end

--- Returns if the component has been registered with the system.
-- @param component string Component to check for.
function Context:isComponent(component) return self.components[component] ~= nil end

--- Returns if the entity has the specified component.
-- @param entity number ID of the entity.
-- @param component string Component to check for.
function Context:hasComponent(entity, component)
    if not self.entityIndex:isAlive(entity) then error('Entity is not alive!') end
    if not self.components[component] then error('Component is not registered!') end

    local component_id = self.components[component]
    local signature    = self.signatures[entity]

    return hasComponent(signature, component_id)
end

--- Returns the specified component data of the given entity.
-- @param entity number ID of the entity.
-- @param component string Component to get data of.
-- @return variant Component data.
function Context:getComponent(entity, component)
    checkType(entity, 'number', 1) checkType(component, 'string', 2)
    return getComponent(self, entity, component)
end

--- Returns the data of multiple components of the given entity.
-- Returns multiple variables, ordered by components given.
-- Each call produces a table, making this operation _very_ costly.
-- GetComponent is always preferred.
-- @param entity number ID of the entity.
-- @param ... string Component(s) to get data of.
-- @retrun variant Component data.
function Context:getComponents(entity, ...)
    checkType(entity, 'number', 1)
    local requested = pack(...)
    local delivered = {}

    for i = 1, #requested do
        checkType(requested[i], 'string', i + 1)
        delivered[i]    = getComponent(self, entity, requested[i])
    end

    return unpack(delivered)
end

--- Returns if the Context has the given system.
-- Takes the _instance_ of a system.
-- @param system System System instance to check for.
function Context:hasSystem(system)
    local systems    = self.systems

    for i = 1, #systems do
        if systems[i] == system then return true end
    end

    return false
end

--- Returns the count of components registered with the Context.
-- @return number
function Context:componentCount() return self.component_count end

-- =========================================================
-- Advanced queries. Only use if you know what you're doing!
-- =========================================================

--- Returns the ID of the given component.
-- @param component string Component to get ID of.
-- @return number Component ID.
function Context:getComponentID(component)
    local id = self.components[component]
    if id == nil then error('Component is not registered!')
    else return id end
end

--- Returns the ComponentArray of the given component.
-- @param component string Component to get ComponentArray of.
-- @return ComponentArray
function Context:getComponentArray(component)
    return self.componentSets[self.components[component]]
end

--- Returns a *reference* to the list of registered components.
-- Keys are the names of the components, while the values are the component IDs.
-- @return table
function Context:getComponentList() return self.components end

--- Returns the signature of the given entity.
-- @return table
function Context:getSignature(entity) return self.signatures[entity] end

--- Returns an iterator traversing the living entities of the Context.
-- @return function
function Context:entities()
    local dense = self.entityIndex.entities.dense -- Direct access.
    local i, n = 0, #dense
    return function()
        i = i + 1
        if i <= n then return dense[i] end
    end
end

--------------------------------------------
-- Exposing some utilities and constructors.
--------------------------------------------

SimpleECS.Context   = Context.new
SimpleECS.Filter    = Filter.new
SimpleECS.System    = System.new
SimpleECS.utils = {
    packDirectory  = packDirectory,
    setComponent   = setComponent,
    clearComponent = clearComponent,
    hasComponent   = hasComponent,
    isSubset       = isSubset,
}

return SimpleECS