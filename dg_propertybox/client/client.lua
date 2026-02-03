local function near(pos, radius)
    if not Config.RequireNear then return true end
    local coords = GetEntityCoords(PlayerPedId())
    return #(coords - pos) <= (radius + 0.2)
end

local function isPolice()
    local data = exports.qbx_core:GetPlayerData()
    local job = data and data.job and data.job.name
    return job and Config.PoliceJobs[job] == true
end

-- Open stash when server tells us to
RegisterNetEvent('pd_propertybox:client:openStash', function(owner)
    if not owner then return end

    exports.ox_inventory:openInventory('stash', {
        id = Config.StashId,
        owner = owner
    })
end)

-- Police deposit prompt (PIN only — no ID, no auto take)
local function depositPrompt()
    if not isPolice() then return end
    if not near(Config.Deposit.coords, Config.Deposit.radius) then return end

    local input = lib.inputDialog('Deposit Property (Police)', {
        {
            type = 'number',
            label = 'Set 4-digit PIN',
            description = 'This PIN will be used for pickup',
            required = true,
            min = 1000,
            max = 9999
        }
    })

    if not input then return end
    TriggerServerEvent('pd_propertybox:server:depositOpenByPin', tostring(input[1]))
end

-- Public pickup prompt
local function pickupPrompt()
    if not near(Config.Pickup.coords, Config.Pickup.radius) then return end

    local input = lib.inputDialog('Retrieve Property', {
        {
            type = 'number',
            label = 'Enter 4-digit PIN',
            required = true,
            min = 1000,
            max = 9999
        }
    })

    if not input then return end
    TriggerServerEvent('pd_propertybox:server:pickupOpenByPin', tostring(input[1]))
end

CreateThread(function()

    -- =========================
    -- Deposit Box (Police Only)
    -- =========================
    exports.ox_target:addSphereZone({
        coords = Config.Deposit.coords,
        radius = Config.Deposit.radius,
        debug = false,
        options = {
            {
                name = 'pd_property_deposit',
                icon = 'fa-solid fa-box-archive',
                label = 'Deposit Property (Police)',
                distance = Config.Deposit.radius, -- ✅ third eye distance limit
                canInteract = function()
                    return isPolice() and near(Config.Deposit.coords, Config.Deposit.radius)
                end,
                onSelect = depositPrompt
            }
        }
    })

    -- =========================
    -- Pickup Box (Public)
    -- =========================
    exports.ox_target:addSphereZone({
        coords = Config.Pickup.coords,
        radius = Config.Pickup.radius,
        debug = false,
        options = {
            {
                name = 'pd_property_pickup',
                icon = 'fa-solid fa-box-open',
                label = 'Retrieve Property',
                distance = Config.Pickup.radius, -- ✅ third eye distance limit
                canInteract = function()
                    return near(Config.Pickup.coords, Config.Pickup.radius)
                end,
                onSelect = pickupPrompt
            }
        }
    })

end)
