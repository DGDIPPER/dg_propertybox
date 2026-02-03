local PINS_FILE = 'data/pins.json'

local activePins = {}
local stashRegistered = false
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

local function invRef(owner)
    return { id = Config.StashId, owner = owner }
end

local function readStash(owner)
    local ok, items = pcall(function()
        return exports.ox_inventory:GetInventoryItems(invRef(owner))
    end)

    if not ok or type(items) ~= 'table' then
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

local function clearStash(owner)
    local items = readStash(owner)
    if not items or #items == 0 then return end

    for _, it in ipairs(items) do
        pcall(function()
            exports.ox_inventory:RemoveItem(invRef(owner), it.name, it.count, it.metadata, it.slot)
        end)

        pcall(function()
            exports.ox_inventory:RemoveItem(Config.StashId, it.name, it.count, it.metadata, it.slot, owner)
        end)
    end
end

local function writeStash(owner, items)
    if type(items) ~= 'table' then return end

    for _, it in ipairs(items) do
        if it and it.name and (it.count or 0) > 0 then
            pcall(function()
                exports.ox_inventory:AddItem(invRef(owner), it.name, it.count, it.metadata, it.slot)
            end)

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

    getPinData(pin)
    rebuildStashFromJson(pin)

    openedPinByPlayer[src] = pin
    TriggerClientEvent('pd_propertybox:client:openStash', src, stashOwner(pin))
end)

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

    rebuildStashFromJson(pin)

    openedPinByPlayer[src] = pin
    TriggerClientEvent('pd_propertybox:client:openStash', src, stashOwner(pin))
end)

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

AddEventHandler('ox_inventory:closedInventory', function(playerId)
    local pin = openedPinByPlayer[playerId]
    if not pin then return end

    openedPinByPlayer[playerId] = nil
    saveStashToJson(pin)
    scheduleAutoClearIfEmpty(pin)
end)

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
