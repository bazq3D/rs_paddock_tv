Framework = {}
local core = nil
local activeFramework = 'standalone'

local function dbg(msg)
    if Config.Debug then
        print(("^4[bazq-paddock-tv] [client/framework] ^7%s"):format(msg))
    end
end

Citizen.CreateThread(function()
    if GetResourceState('ox_core') == 'started' then
        core = exports.ox_core
        activeFramework = 'ox'
        dbg("ox_core framework detected.")
    elseif GetResourceState('devix-core') == 'started' then
        pcall(function()
            core = exports['devix-core']:GetCoreObject()
        end)
        activeFramework = 'devix'
        dbg("devix-core framework detected.")
    elseif GetResourceState('qb-core') == 'started' then
        core = exports['qb-core']:GetCoreObject()
        activeFramework = 'qb'
        dbg("qb-core framework detected.")
    elseif GetResourceState('qbox') == 'started' then
        core = exports['qb-core']:GetCoreObject() -- qbox uses qb-core compatibility layer
        activeFramework = 'qbox'
        dbg("qbox framework detected.")
    elseif GetResourceState('es_extended') == 'started' then
        pcall(function()
            core = exports['es_extended']:getSharedObject()
        end)
        activeFramework = 'esx'
        dbg("ESX framework detected.")
    else
        dbg("Standalone mode activated (no core framework detected).")
    end
end)

-- Display Client Notification
function Framework.ShowNotification(msg, type)
    if activeFramework == 'ox' then
        lib.notify({
            title = _L('menu_title'),
            description = msg,
            type = type or 'info'
        })
    elseif activeFramework == 'qb' or activeFramework == 'qbox' or activeFramework == 'devix' then
        if core and core.Functions and core.Functions.Notify then
            core.Functions.Notify(msg, type or 'primary')
        else
            TriggerEvent('QBCore:Notify', msg, type or 'primary')
        end
    elseif activeFramework == 'esx' then
        if core and core.ShowNotification then
            core.ShowNotification(msg)
        else
            TriggerEvent('esx:showNotification', msg)
        end
    else
        -- Standalone notification fallback
        SetNotificationTextEntry("STRING")
        AddTextComponentString(msg)
        DrawNotification(false, false)
    end
end

-- Server-triggered notification event listener
RegisterNetEvent('rs_paddock_tv:client:showNotification', function(msg, type)
    Framework.ShowNotification(msg, type)
end)

-- Open Keyboard Input Dialog
function Framework.OpenInput(title, rows, cb)
    -- ox_lib dialog input
    if GetResourceState('ox_lib') == 'started' then
        local inputs = {}
        for _, row in ipairs(rows) do
            table.insert(inputs, {
                type = 'input',
                label = row.label,
                placeholder = row.placeholder,
                required = true
            })
        end
        local input = lib.inputDialog(title, inputs)
        if input then
            cb(input)
        else
            cb(nil)
        end
        return
    end

    -- qb-input
    if GetResourceState('qb-input') == 'started' then
        local inputs = {}
        for i, row in ipairs(rows) do
            table.insert(inputs, {
                text = row.label,
                name = "input_" .. i,
                type = "text",
                isRequired = true,
                placeholder = row.placeholder
            })
        end
        local keyboard = exports['qb-input']:ShowInput({
            header = title,
            submitText = "Submit",
            inputs = inputs
        })
        if keyboard then
            local results = {}
            for i = 1, #rows do
                table.insert(results, keyboard["input_" .. i])
            end
            cb(results)
        else
            cb(nil)
        end
        return
    end

    -- Standalone Keyboard Input
    Citizen.CreateThread(function()
        local results = {}
        for _, row in ipairs(rows) do
            AddTextEntry('FMMC_KEY_TIP1', row.label)
            DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", row.placeholder or "", "", "", "", 100)
            while UpdateOnscreenKeyboard() == 0 do
                Wait(0)
            end
            if UpdateOnscreenKeyboard() == 1 then
                local result = GetOnscreenKeyboardResult()
                table.insert(results, result)
            else
                cb(nil)
                return
            end
        end
        cb(results)
    end)
end
