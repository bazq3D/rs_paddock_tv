local tvStates = {}

-- bazq style local debug print helper
local function dbg(msg)
    if Config.Debug then
        print(("^4[bazq-rs_paddock_tv] ^7%s"):format(msg))
    end
end

-- Find closest Paddock location key, location table, and distance
local function GetClosestLocation()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestLocKey = nil
    local closestLoc = nil
    local minDistance = 99999.0

    for locKey, loc in pairs(Config.Locations) do
        local dist = #(playerCoords - loc.coords)
        if dist < minDistance then
            minDistance = dist
            closestLocKey = locKey
            closestLoc = loc
        end
    end
    return closestLocKey, closestLoc, minDistance
end

-- Update interior entity sets based on TV playback states for a specific location
local function SyncTvEntitySets(locKey, closestLoc)
    if not locKey then return end
    
    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    
    local interiorId = GetInteriorFromEntity(playerPed)
    if not interiorId or interiorId == 0 then
        interiorId = GetInteriorAtCoords(pCoords.x, pCoords.y, pCoords.z)
    end
    if not interiorId or interiorId == 0 then
        if closestLoc then
            interiorId = GetInteriorAtCoords(closestLoc.coords.x, closestLoc.coords.y, closestLoc.coords.z)
        end
    end

    if not interiorId or interiorId == 0 then return end

    local refreshNeeded = false
    local locTvStates = tvStates[locKey] or {}

    for tvId, tvConfig in pairs(Config.TVs) do
        if tvConfig.entitySet then
            local state = locTvStates[tvId]
            local isTvOn = state and state.playing and state.url ~= ""

            if isTvOn then
                if not IsInteriorEntitySetActive(interiorId, tvConfig.entitySet) then
                    ActivateInteriorEntitySet(interiorId, tvConfig.entitySet)
                    refreshNeeded = true
                    dbg(("[%s] TV #%d TURNED ON -> EntitySet Active: %s (Interior ID: %d)"):format(locKey, tvId, tvConfig.entitySet, interiorId))
                end
            else
                if IsInteriorEntitySetActive(interiorId, tvConfig.entitySet) then
                    DeactivateInteriorEntitySet(interiorId, tvConfig.entitySet)
                    refreshNeeded = true
                    dbg(("[%s] TV #%d TURNED OFF -> EntitySet Inactive: %s (Interior ID: %d)"):format(locKey, tvId, tvConfig.entitySet, interiorId))
                end
            end
        end
    end

    if refreshNeeded then
        RefreshInterior(interiorId)
    end
end

-- Shared DUI Browser Pool (Maps streamKey -> Shared DUI Instance)
local sharedDuis = {}
local activeTvDuiKeys = {}
local duiInstancesIsReplaced = {}

local function ExtractYoutubeId(url)
    if not url or url == "" then return "" end
    local videoId = string.match(url, "v=([%w_%-]+)") or string.match(url, "youtu%.be/([%w_%-]+)") or url
    return videoId
end

local function GetStreamKey(streamUrl, streamTime)
    if not streamUrl or streamUrl == "" then return nil end
    if streamUrl == "weather_channel" then
        return "weather_channel"
    end

    local videoId = ExtractYoutubeId(streamUrl)
    local t = tonumber(streamTime) or 0
    -- Bucket timestamp into 10-second sync windows so synchronized TVs share the exact same DUI
    local timeBucket = math.floor(t / 10) * 10
    return ("yt_%s_t%d"):format(videoId, timeBucket)
end

local function GetOrCreateSharedDui(streamKey, streamUrl, streamTime)
    if not streamKey then return nil end

    if sharedDuis[streamKey] and sharedDuis[streamKey].duiObject then
        return sharedDuis[streamKey]
    end

    local isWeatherChannel = (streamUrl == "weather_channel")
    local resourceName = GetCurrentResourceName()
    local duiUrl = isWeatherChannel 
        and ("https://cfx-nui-%s/html/weather_channel/index.html"):format(resourceName)
        or ("https://cfx-nui-%s/html/tv.html?resource=%s"):format(resourceName, resourceName)

    local safeKey = string.gsub(streamKey, "[^%w_]", "_")
    local runtimeTxdName = ("paddock_tv_shared_txd_%s"):format(safeKey)
    local runtimeTxnName = ("paddock_tv_shared_txn_%s"):format(safeKey)

    dbg(("Creating Shared DUI Instance [Key: %s | Type: %s]: %s"):format(streamKey, isWeatherChannel and "weather_channel" or "youtube", duiUrl))

    local duiObject = CreateDui(duiUrl, Config.DuiWidth, Config.DuiHeight)
    local duiHandle = GetDuiHandle(duiObject)

    local txd = CreateRuntimeTxd(runtimeTxdName)
    local texture = CreateRuntimeTextureFromDuiHandle(txd, runtimeTxnName, duiHandle)

    sharedDuis[streamKey] = {
        key = streamKey,
        type = isWeatherChannel and "weather_channel" or "youtube",
        duiObject = duiObject,
        duiHandle = duiHandle,
        txd = txd,
        texture = texture,
        runtimeTxdName = runtimeTxdName,
        runtimeTxnName = runtimeTxnName,
        isNew = true
    }

    return sharedDuis[streamKey]
end

local function CleanUnusedSharedDuis()
    local inUseKeys = {}
    for tvId, key in pairs(activeTvDuiKeys) do
        inUseKeys[key] = true
    end

    for key, instance in pairs(sharedDuis) do
        if not inUseKeys[key] then
            dbg(("Destroying unused shared DUI instance [Key: %s]"):format(key))
            if instance.duiObject then
                DestroyDui(instance.duiObject)
            end
            sharedDuis[key] = nil
        end
    end
end

-- Send DUI Message to shared browser instance
local function SendDuiAction(tvId, actionData)
    if not actionData or not actionData.url or actionData.url == "" then return end

    local streamKey = GetStreamKey(actionData.url, actionData.time)
    local instance = GetOrCreateSharedDui(streamKey, actionData.url, actionData.time)
    if not instance or not instance.duiObject then return end

    if instance.type == "weather_channel" then return end

    local payload = json.encode(actionData)
    SendDuiMessage(instance.duiObject, payload)

    if instance.isNew then
        instance.isNew = false
        Citizen.SetTimeout(350, function()
            if sharedDuis[streamKey] and sharedDuis[streamKey].duiObject then
                SendDuiMessage(sharedDuis[streamKey].duiObject, payload)
            end
        end)
        Citizen.SetTimeout(700, function()
            if sharedDuis[streamKey] and sharedDuis[streamKey].duiObject then
                SendDuiMessage(sharedDuis[streamKey].duiObject, payload)
            end
        end)
    end
end

-- Receive real-time weather channel data pushed from server
RegisterNetEvent('rs_paddock_tv:client:weatherChannelData', function(data)
    for key, instance in pairs(sharedDuis) do
        if instance and instance.type == "weather_channel" and instance.duiObject then
            SendDuiMessage(instance.duiObject, json.encode({
                type = 'rsweather:channel:data',
                data = data
            }))
        end
    end
end)

-- Restore original texture when TV is turned off
local function RestoreTVTexture(tvId)
    if not duiInstancesIsReplaced[tvId] then return end

    local tvConfig = Config.TVs[tvId]
    if not tvConfig then return end

    local targetTxd = tvConfig.txd or "rs_paddock_tvapp_txd"
    local targetTxn = tvConfig.txn or ("rs_paddock_tvapp%d"):format(tvId)

    RemoveReplaceTexture(targetTxd, targetTxn)
    RemoveReplaceTexture(targetTxd, tvConfig.model or ("rs_paddock_tv_app%d"):format(tvId))

    if tvConfig.model then
        RemoveReplaceTexture(tvConfig.model, targetTxn)
        RemoveReplaceTexture(tvConfig.model, tvConfig.model)
    end

    activeTvDuiKeys[tvId] = nil
    duiInstancesIsReplaced[tvId] = false
    dbg(("Texture restored [TV #%d]"):format(tvId))

    CleanUnusedSharedDuis()
end

-- Replace target TV texture with Shared DUI runtime texture
local function ReplaceTVTexture(tvId, streamUrl, streamTime)
    if not streamUrl or streamUrl == "" then return end

    local streamKey = GetStreamKey(streamUrl, streamTime)
    local instance = GetOrCreateSharedDui(streamKey, streamUrl, streamTime)
    if not instance then return end

    local oldKey = activeTvDuiKeys[tvId]
    if oldKey == streamKey and duiInstancesIsReplaced[tvId] then return end

    if oldKey and oldKey ~= streamKey then
        RestoreTVTexture(tvId)
    end

    local tvConfig = Config.TVs[tvId]
    if not tvConfig then return end

    local targetTxd = tvConfig.txd or "rs_paddock_tvapp_txd"
    local targetTxn = tvConfig.txn or ("rs_paddock_tvapp%d"):format(tvId)

    -- 1. Replace texture on shared TXD (rs_paddock_tvapp_txd -> rs_paddock_tvapp1..7)
    AddReplaceTexture(targetTxd, targetTxn, instance.runtimeTxdName, instance.runtimeTxnName)
    AddReplaceTexture(targetTxd, tvConfig.model or ("rs_paddock_tv_app%d"):format(tvId), instance.runtimeTxdName, instance.runtimeTxnName)

    -- 2. Replace texture directly on prop model (rs_paddock_tv_app1..7)
    if tvConfig.model then
        AddReplaceTexture(tvConfig.model, targetTxn, instance.runtimeTxdName, instance.runtimeTxnName)
        AddReplaceTexture(tvConfig.model, tvConfig.model, instance.runtimeTxdName, instance.runtimeTxnName)
    end

    activeTvDuiKeys[tvId] = streamKey
    duiInstancesIsReplaced[tvId] = true
    dbg(("Shared Texture replaced [TV #%d | Key: %s]: %s/%s -> %s/%s"):format(tvId, streamKey, targetTxd, targetTxn, instance.runtimeTxdName, instance.runtimeTxnName))

    CleanUnusedSharedDuis()
end

-- Destroy all DUIs on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        dbg("Resource stopping, cleaning up all shared DUI instances...")
        for tvId, _ in pairs(Config.TVs) do
            RestoreTVTexture(tvId)
        end
        for key, instance in pairs(sharedDuis) do
            if instance and instance.duiObject then
                DestroyDui(instance.duiObject)
            end
        end
        sharedDuis = {}
    end
end)

-- Extract TV ID from targeted entity model
local function GetTvIdFromEntity(entity)
    if entity and DoesEntityExist(entity) then
        local entityModel = GetEntityModel(entity)
        for tvId, tvConfig in pairs(Config.TVs) do
            if tvConfig.model and GetHashKey(tvConfig.model) == entityModel then
                return tvId
            end
        end
    end
    return 1
end

-- Dynamic volume calculation and state sync thread per location
Citizen.CreateThread(function()
    while true do
        Wait(500)
        local closestLocKey, closestLoc, distance = GetClosestLocation()
        
        if closestLocKey and distance <= Config.MaxRenderDistance then
            SyncTvEntitySets(closestLocKey, closestLoc)

            local locTvStates = tvStates[closestLocKey] or {}

            -- Identify primary audio master TV for each active stream URL (prevents audio overlap/echo)
            local activeMasterTvs = {}
            if Config.MuteDuplicateAudio ~= false then
                for tvId = 1, 7 do
                    local state = locTvStates[tvId]
                    if state and state.playing and state.url ~= "" then
                        local urlKey = state.url
                        if not activeMasterTvs[urlKey] then
                            activeMasterTvs[urlKey] = tvId
                        end
                    end
                end
            end

            for tvId, tvConfig in pairs(Config.TVs) do
                local state = locTvStates[tvId]
                local instance = duiInstances[tvId]

                if state and state.playing and state.url ~= "" then
                    ReplaceTVTexture(tvId, state.url, state.time)
                    
                    local isMasterForAudio = true
                    if Config.MuteDuplicateAudio ~= false and activeMasterTvs[state.url] then
                        if activeMasterTvs[state.url] ~= tvId then
                            isMasterForAudio = false
                        end
                    end

                    local volPercent = 0
                    if isMasterForAudio and distance <= Config.MaxRenderDistance then
                        local progress = distance / Config.MaxRenderDistance
                        local volumeMultiplier = 1.0 - progress
                        volPercent = math.floor(state.volume * volumeMultiplier)
                        if volPercent < 0 then volPercent = 0 end
                    end

                    SendDuiAction(tvId, {
                        action = 'play',
                        url = state.url,
                        time = state.time,
                        volume = volPercent
                    })
                else
                    RestoreTVTexture(tvId)
                end
            end
        else
            -- Player far from any Paddock location: restore textures and clean shared DUIs
            for tvId, _ in pairs(Config.TVs) do
                RestoreTVTexture(tvId)
            end
        end
    end
end)

-- Global state synchronization event from server
RegisterNetEvent('rs_paddock_tv:client:syncAllTvStates', function(states)
    tvStates = states or {}
    dbg("Received all location TV states from server.")
    
    local closestLocKey, closestLoc, distance = GetClosestLocation()
    if closestLocKey and distance <= Config.MaxRenderDistance then
        SyncTvEntitySets(closestLocKey, closestLoc)
        local locTvStates = tvStates[closestLocKey] or {}
        SendNUIMessage({
            action = 'syncAllStates',
            tvStates = locTvStates,
            locationKey = closestLocKey
        })
    end
end)

-- Single TV state synchronization event from server (Per Location)
RegisterNetEvent('rs_paddock_tv:client:syncTvState', function(locKey, tvId, state)
    if not tvStates[locKey] then tvStates[locKey] = {} end
    tvStates[locKey][tvId] = state
    
    dbg(("[%s] TV #%d state updated -> URL: %s | Playing: %s"):format(locKey, tvId, state.url, tostring(state.playing)))

    local closestLocKey, closestLoc, distance = GetClosestLocation()
    
    -- Only trigger active DUI / EntitySet / NUI updates if player is at this location
    if closestLocKey == locKey then
        local instance = duiInstances[tvId]

        if state.url ~= "" and state.playing then
            GetOrCreateTvDui(tvId)
            ReplaceTVTexture(tvId)

            local volPercent = state.volume or Config.DefaultVolume
            if distance <= Config.MaxRenderDistance then
                local progress = distance / Config.MaxRenderDistance
                volPercent = math.floor(state.volume * (1.0 - progress))
                if volPercent < 0 then volPercent = 0 end
            end

            SendDuiAction(tvId, {
                action = 'play',
                url = state.url,
                time = state.time,
                volume = volPercent
            })
        else
            if instance and instance.duiObject then
                if state.url == "" then
                    RestoreTVTexture(tvId)
                    SendDuiAction(tvId, { action = 'stop' })
                else
                    SendDuiAction(tvId, { action = 'pause' })
                end
            end
        end

        SyncTvEntitySets(locKey, closestLoc)

        -- Update NUI state if control panel is open
        SendNUIMessage({
            action = 'syncState',
            tvId = tvId,
            state = state,
            tvStates = tvStates[locKey],
            locationKey = locKey
        })
    end
end)

-- Initial map loading: request server state and sync entity sets
Citizen.CreateThread(function()
    Wait(1000)
    local closestLocKey, closestLoc = GetClosestLocation()
    if closestLocKey then
        SyncTvEntitySets(closestLocKey, closestLoc)
    end
    TriggerServerEvent('rs_paddock_tv:server:requestSync')
end)

-- Menu opening client event
RegisterNetEvent('rs_paddock_tv:client:openMenu', function(targetTvId)
    local closestLocKey = GetClosestLocation()
    TriggerServerEvent('rs_paddock_tv:server:openMenu', targetTvId, closestLocKey)
end)

-- Build and display NUI Dashboard
RegisterNetEvent('rs_paddock_tv:client:showMenu', function(targetTvId, locKey, locTvStates)
    local selectedTvId = tonumber(targetTvId) or 1
    dbg(("Opening NUI Control Panel... Selected TV: #%d | Location: %s"):format(selectedTvId, tostring(locKey)))
    
    local closestLocKey, closestLoc, distance = GetClosestLocation()
    locKey = locKey or closestLocKey
    
    if closestLoc and distance <= Config.InteractDistance + 5.0 then
        local currentLang = Config.Locale or 'en'
        local activeLocales = Locales[currentLang] or Locales['en']

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'show',
            tvList = Config.TVs,
            tvGroups = Config.TVGroups,
            selectedTvId = selectedTvId,
            locationKey = locKey,
            tvStates = locTvStates or (tvStates[locKey] or {}),
            locales = activeLocales,
            localeName = currentLang,
            locationLabel = closestLoc.label,
            locationCoords = ("%.2f, %.2f, %.2f"):format(closestLoc.coords.x, closestLoc.coords.y, closestLoc.coords.z)
        })
    else
        Framework.ShowNotification(_L('not_near_tv'), 'error')
    end
end)

-- NUI Close Callback
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- NUI Update State Callback
RegisterNUICallback('updateState', function(data, cb)
    TriggerServerEvent('rs_paddock_tv:server:updateState', data)
    cb('ok')
end)

-- Target Setup (Paddock TV Models & Remote Control Props)
local function SetupOxTarget()
    local models = {}
    local added = {}

    for _, model in ipairs(Config.TVModels) do
        if not added[model] then
            table.insert(models, model)
            added[model] = true
        end
    end
    for _, remote in ipairs(Config.RemoteModels) do
        if not added[remote] then
            table.insert(models, remote)
            added[remote] = true
        end
    end

    exports.ox_target:addModel(models, {
        {
            name = 'paddock_tv_control',
            icon = 'fa-solid fa-tv',
            label = _L('control_tv'),
            distance = Config.InteractDistance,
            onSelect = function(data)
                local tvId = GetTvIdFromEntity(data and data.entity)
                TriggerEvent('rs_paddock_tv:client:openMenu', tvId)
            end
        }
    })
end

local function SetupQbTarget()
    local models = {}
    local added = {}

    for _, model in ipairs(Config.TVModels) do
        if not added[model] then
            table.insert(models, model)
            added[model] = true
        end
    end
    for _, remote in ipairs(Config.RemoteModels) do
        if not added[remote] then
            table.insert(models, remote)
            added[remote] = true
        end
    end

    exports['qb-target']:AddTargetModel(models, {
        options = {
            {
                type = "client",
                event = "rs_paddock_tv:client:checkTargetLocation",
                icon = "fas fa-tv",
                label = _L('control_tv'),
            }
        },
        distance = Config.InteractDistance
    })
end

RegisterNetEvent('rs_paddock_tv:client:checkTargetLocation', function(data)
    local entity = data and data.entity
    local tvId = GetTvIdFromEntity(entity)
    TriggerEvent('rs_paddock_tv:client:openMenu', tvId)
end)

Citizen.CreateThread(function()
    Wait(2000)
    local targetSystem = Config.TargetSystem
    if targetSystem == 'auto' then
        if GetResourceState('ox_target') == 'started' then
            targetSystem = 'ox_target'
        elseif GetResourceState('qb-target') == 'started' then
            targetSystem = 'qb-target'
        else
            targetSystem = 'none'
        end
    end

    if targetSystem == 'ox_target' then
        SetupOxTarget()
        dbg("ox_target integration completed.")
    elseif targetSystem == 'qb-target' then
        SetupQbTarget()
        dbg("qb-target integration completed.")
    else
        dbg("No target framework resource detected.")
    end
end)

-- Chat Commands (Optional Standalone Alternatives)
Citizen.CreateThread(function()
    Wait(2500)
    if Config.EnableCommands then
        local cmdMenu = (Config.Commands and Config.Commands.menu) or 'tvmenu'
        local cmdPlay = (Config.Commands and Config.Commands.play) or 'tvplay'
        local cmdStop = (Config.Commands and Config.Commands.stop) or 'tvstop'
        local cmdVolume = (Config.Commands and Config.Commands.volume) or 'tvvolume'

        RegisterCommand(cmdPlay, function(source, args, rawCommand)
            local tvId = tonumber(args[1]) or 1
            local url = args[2] or args[1]
            if url then
                TriggerServerEvent('rs_paddock_tv:server:updateState', { targetScope = 'single', tvId = tvId, action = 'play', url = url })
            else
                Framework.ShowNotification(_L('invalid_url'), 'error')
            end
        end, false)

        RegisterCommand(cmdStop, function(source, args, rawCommand)
            local tvId = tonumber(args[1]) or 1
            TriggerServerEvent('rs_paddock_tv:server:updateState', { targetScope = 'single', tvId = tvId, action = 'stop' })
        end, false)

        RegisterCommand(cmdVolume, function(source, args, rawCommand)
            local tvId = tonumber(args[1]) or 1
            local vol = tonumber(args[2])
            if vol and vol >= 0 and vol <= 100 then
                TriggerServerEvent('rs_paddock_tv:server:updateState', { targetScope = 'single', tvId = tvId, action = 'volume', volume = vol })
            else
                Framework.ShowNotification(_L('invalid_volume'), 'error')
            end
        end, false)

        RegisterCommand(cmdMenu, function(source, args, rawCommand)
            local targetTvId = tonumber(args[1]) or 1
            local closestLocKey, closestLoc, distance = GetClosestLocation()
            if closestLocKey and distance <= Config.InteractDistance + 5.0 then
                TriggerEvent('rs_paddock_tv:client:openMenu', targetTvId)
            else
                Framework.ShowNotification(_L('not_near_tv'), 'error')
            end
        end, false)

        dbg(("Chat commands registered -> /%s, /%s, /%s, /%s"):format(cmdMenu, cmdPlay, cmdStop, cmdVolume))
    else
        dbg("Chat commands disabled via Config.EnableCommands.")
    end
end)

