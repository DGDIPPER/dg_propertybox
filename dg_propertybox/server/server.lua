-- pd_propertybox/server.lua
-- JSON persistence for PIN stashes (no SQL required)

local PINS_FILE = 'data/pins.json'

-- activePins structure:
-- activePins["1234"] = { items = { {name="", count=, metadata=, slot=} ... } }
local activePins = {}
local stashRegistered = false

-- Track which pin a player currently has open so we only save that one on close
local openedPinByPlayer = {}

local function loadPins()
    local raw = LoadResourceFile(GetCurrentResourceName(), PINS_FILE)
    if not raw or raw == '' then
        activePins = {}
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    activePins = (ok and type(decoded) == 'table') and decoded or {}
end

local function savePins()
    SaveResourceFile(GetCurrentResourceName(), PINS_FILE, json.encode(activePins, { indent = true }), -1)
end

local function isPolice(src)
    local p = exports.qbx_core:GetPlayer(src)
    local job = p and p.PlayerData and p.PlayerData.job and p.PlayerData.job.name
    return job and Config.PoliceJobs[job] == true
end

local function pinValid(pin)
    return tostring(pin):match('^%d%d%d%d$') ~= nil
end

local function stashOwner(pin)
    return 'pin:' .. tostring(pin)
end

local function ensureStash()
    if stashRegistered then return end

    -- owner=true => owner-based stash, we pass owner = "pin:1234"
    exports.ox_inventory:RegisterStash(
        Config.StashId,
        Config.StashLabel,
        Config.StashSlots,
        Config.StashMaxWeight,
        true
    )

    stashRegistered = true
end

local function getPinData(pin)
    pin = tostring(pin)
    if type(activePins[pin]) ~= 'table' then
        activePins[pin] = { items = {} }
    end
    if type(activePins[pin].items) ~= 'table' then
        activePins[pin].items = {}
    end
    return activePins[pin]
end

-- Build the "inventory reference" the way your client opens it:
-- openInventory('stash', { id=Config.StashId, owner=owner })
local function invRef(owner)
    return { id = Config.StashId, owner = owner }
end

-- Version-tolerant read of stash items
local function readStash(owner)
    local ok, items = pcall(function()
        -- many ox versions accept a table {id, owner}
        return exports.ox_inventory:GetInventoryItems(invRef(owner))
    end)

    if not ok or type(items) ~= 'table' then
        -- fallback: some versions want (id, owner)
        ok, items = pcall(function()
            return exports.ox_inventory:GetInventoryItems(Config.StashId, owner)
        end)
    end

    if not ok or type(items) ~= 'table' then
        return {}
    end

    local out = {}
    for _, it in pairs(items) do
        if it and it.name and (it.count or 0) > 0 then
            out[#out + 1] = {
                name = it.name,
                count = it.count,
                metadata = it.metadata,
                slot = it.slot
            }
        end
    end
    return out
end

-- Remove everything currently in the stash (so we can rebuild from json)
local function clearStash(owner)
    local items = readStash(owner)
    if not items or #items == 0 then return end

    for _, it in ipairs(items) do
        pcall(function()
            exports.ox_inventory:RemoveItem(invRef(owner), it.name, it.count, it.metadata, it.slot)
        end)

        -- fallback signature (id, owner, ...)
        pcall(function()
            exports.ox_inventory:RemoveItem(Config.StashId, it.name, it.count, it.metadata, it.slot, owner)
        end)
    end
end

-- Add items from json into stash
local function writeStash(owner, items)
    if type(items) ~= 'table' then return end

    for _, it in ipairs(items) do
        if it and it.name and (it.count or 0) > 0 then
            pcall(function()
                exports.ox_inventory:AddItem(invRef(owner), it.name, it.count, it.metadata, it.slot)
            end)

            -- fallback signature (id, owner, ...)
            pcall(function()
                exports.ox_inventory:AddItem(Config.StashId, it.name, it.count, it.metadata, it.slot, owner)
            end)
        end
    end
end

local function stashHasItems(owner)
    local items = readStash(owner)
    for _, it in ipairs(items) do
        if (it.count or 0) > 0 then
            return true
        end
    end
    return false
end

local function rebuildStashFromJson(pin)
    pin = tostring(pin)
    ensureStash()

    local owner = stashOwner(pin)
    local data = getPinData(pin)

    -- make stash match json exactly
    clearStash(owner)
    writeStash(owner, data.items)
end

local function saveStashToJson(pin)
    pin = tostring(pin)
    local owner = stashOwner(pin)
    local data = getPinData(pin)

    data.items = readStash(owner)
    savePins()
end

-- After close/open, if stash ends up empty, allow PIN reuse
local function scheduleAutoClearIfEmpty(pin)
    pin = tostring(pin)
    SetTimeout(6000, function()
        if not activePins[pin] then return end

        local owner = stashOwner(pin)
        if not stashHasItems(owner) then
            activePins[pin] = nil
            savePins()
        end
    end)
end

-- ============================================================
-- EVENTS
-- ============================================================

-- Police: open stash for deposit (manual)
RegisterNetEvent('pd_propertybox:server:depositOpenByPin', function(pin)
    local src = source
    pin = tostring(pin)

    if not isPolice(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Property Box', description = 'Not authorized.', type = 'error' })
        return
    end

    if not pinValid(pin) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Property Box', description = 'PIN must be 4 digits.', type = 'error' })
        return
    end

    -- Reserve pin record if missing
    getPinData(pin)

    -- Restore stash from json so it persists without SQL
    rebuildStashFromJson(pin)

    openedPinByPlayer[src] = pin
    TriggerClientEvent('pd_propertybox:client:openStash', src, stashOwner(pin))
end)

-- Public pickup
RegisterNetEvent('pd_propertybox:server:pickupOpenByPin', function(pin)
    local src = source
    pin = tostring(pin)

    if not pinValid(pin) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Property Box', description = 'PIN must be 4 digits.', type = 'error' })
        return
    end

    if not activePins[pin] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Property Box', description = 'No property found for that PIN.', type = 'error' })
        return
    end

    -- Restore stash from json
    rebuildStashFromJson(pin)

    openedPinByPlayer[src] = pin
    TriggerClientEvent('pd_propertybox:client:openStash', src, stashOwner(pin))
end)

-- Optional manual clear (police)
RegisterCommand('propertyclear', function(source, args)
    local src = source
    if src == 0 then return end
    if not isPolice(src) then return end

    local pin = tostring(args[1] or '')
    if not pinValid(pin) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Property Box', description = 'Use: /propertyclear 1234', type = 'error' })
        return
    end

    if activePins[pin] then
        activePins[pin] = nil
        savePins()
        TriggerClientEvent('ox_lib:notify', src, { title = 'Property Box', description = ('Cleared PIN %s.'):format(pin), type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Property Box', description = 'PIN not found.', type = 'error' })
    end
end)

-- Save stash when inventory closes (most reliable “no SQL” persistence point)
AddEventHandler('ox_inventory:closedInventory', function(playerId)
    local pin = openedPinByPlayer[playerId]
    if not pin then return end

    openedPinByPlayer[playerId] = nil

    -- Save current stash state into pins.json
    saveStashToJson(pin)

    -- If empty, free the pin shortly after
    scheduleAutoClearIfEmpty(pin)
end)

-- Cleanup if player drops while stash open (still try saving)
AddEventHandler('playerDropped', function()
    local src = source
    local pin = openedPinByPlayer[src]
    if not pin then return end

    openedPinByPlayer[src] = nil
    saveStashToJson(pin)
    scheduleAutoClearIfEmpty(pin)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    loadPins()
    ensureStash()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    savePins()
end)
