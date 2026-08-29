-- bazq style local debug print helper
local function dbg(msg)
    if Config.Debug then
        print(("^4[bazq-rs_paddock_tv] ^7%s"):format(msg))
    end
end

-- TV State Store per Location: tvStates[locationKey][tvId]
local tvStates = {}

local function InitTVStates()
    for locKey, _ in pairs(Config.Locations) do
        tvStates[locKey] = {}
        for tvId, _ in pairs(Config.TVs) do
            tvStates[locKey][tvId] = {
                url = "",
                playing = false,
                time = 0,
                volume = Config.DefaultVolume
            }
        end
    end
end
InitTVStates()

-- =============================================================================
-- RETRO STORE RADIO (rs_radio) INTEGRATION
-- =============================================================================
local rsRadioEmitters = {}

local function SetupRsRadioEmitters()
    if not Config.UseRsRadio or GetResourceState('rs_radio') ~= 'started' then
        return
    end

    dbg("Initializing rs_radio static emitters for paddock locations...")
    for locKey, loc in pairs(Config.Locations) do
        local emitterSpec = {
            label = ("paddock_tv_%s"):format(locKey),
            pos = loc.coords,
            stationId = (Config.RsRadio and Config.RsRadio.stationId) or "south",
            radius = (Config.RsRadio and Config.RsRadio.radius) or 25.0,
            volume = (Config.RsRadio and Config.RsRadio.volume) or 0.4,
            interiorOnly = (Config.RsRadio and Config.RsRadio.interiorOnly ~= nil) and Config.RsRadio.interiorOnly or true,
            enabled = (Config.RsRadio and Config.RsRadio.enabled ~= nil) and Config.RsRadio.enabled or true
        }

        local success, idOrErr = pcall(function()
            return exports.rs_radio:createStaticEmitter(emitterSpec)
        end)

        if success and idOrErr and type(idOrErr) == "number" then
            rsRadioEmitters[locKey] = idOrErr
            dbg(("Successfully created rs_radio static emitter #%d for location [%s]"):format(idOrErr, locKey))
        else
            dbg(("Could not create rs_radio static emitter for location [%s]: %s"):format(locKey, tostring(idOrErr)))
        end
    end
end

Citizen.CreateThread(function()
    Wait(1500)
    SetupRsRadioEmitters()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'rs_radio' then
        Wait(1000)
        SetupRsRadioEmitters()
    end
end)

-- Time Tracking Thread (Increments elapsed time for all playing TVs per location)
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        for locKey, locationTvStates in pairs(tvStates) do
            for tvId, state in pairs(locationTvStates) do
                if state.playing and state.url ~= "" then
                    state.time = state.time + 1
                end
            end
        end
    end
end)

-- Find location key where player is currently located
local function GetPlayerLocationKey(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil, nil end
    
    local coords = GetEntityCoords(ped)
    for locKey, loc in pairs(Config.Locations) do
        local dist = #(coords - loc.coords)
        if dist <= Config.MaxRenderDistance + 15.0 then
            return locKey, loc
        end
    end
    return nil, nil
end

-- Synchronize all location TV states for newly connected players
RegisterNetEvent('rs_paddock_tv:server:requestSync', function()
    local src = source
    dbg(("Player #%s requested full location TV state sync. Sending..."):format(src))
    TriggerClientEvent('rs_paddock_tv:client:syncAllTvStates', src, tvStates)
end)

-- Open control menu with permission & location check
RegisterNetEvent('rs_paddock_tv:server:openMenu', function(targetTvId, reqLocKey)
    local src = source
    local tvId = tonumber(targetTvId) or 1
    
    local locKey, locData = GetPlayerLocationKey(src)
    if not locKey then
        if reqLocKey and Config.Locations[reqLocKey] then
            locKey = reqLocKey
        else
            TriggerClientEvent('rs_paddock_tv:client:showNotification', src, _L('not_near_tv'), 'error')
            return
        end
    end

    if Framework.HasPermission(src) then
        local currentLocStates = tvStates[locKey] or {}
        TriggerClientEvent('rs_paddock_tv:client:showMenu', src, tvId, locKey, currentLocStates)
    else
        TriggerClientEvent('rs_paddock_tv:client:showNotification', src, _L('no_permission'), 'error')
    end
end)

-- Apply state change to a specific TV ID at a specific location
local function ApplyStateToTV(locKey, tvId, data)
    if not tvStates[locKey] then tvStates[locKey] = {} end
    if not tvStates[locKey][tvId] then
        tvStates[locKey][tvId] = {
            url = "",
            playing = false,
            time = 0,
            volume = Config.DefaultVolume
        }
    end

    local state = tvStates[locKey][tvId]

    if data.action == 'play' then
        if data.url and data.url ~= "" then
            state.url = data.url
            state.playing = true
            state.time = 0
            dbg(("[%s] TV #%d started new video feed: %s"):format(locKey, tvId, data.url))
        end
    elseif data.action == 'pause' then
        state.playing = false
        dbg(("[%s] TV #%d paused."):format(locKey, tvId))
    elseif data.action == 'resume' then
        state.playing = true
        dbg(("[%s] TV #%d resumed."):format(locKey, tvId))
    elseif data.action == 'volume' then
        if data.volume and data.volume >= 0 and data.volume <= 100 then
            state.volume = data.volume
            dbg(("[%s] TV #%d volume updated to %d%%"):format(locKey, tvId, data.volume))
        end
    elseif data.action == 'stop' then
        state.url = ""
        state.playing = false
        state.time = 0
        dbg(("[%s] TV #%d stopped and cleared."):format(locKey, tvId))
    end

    TriggerClientEvent('rs_paddock_tv:client:syncTvState', -1, locKey, tvId, state)
end

-- Send Discord Webhook Log Notification
local function SendDiscordLog(source, locKey, scope, targetTvId, groupId, action, url, volume)
    if not Config.DiscordLogs or not Config.DiscordWebhook or Config.DiscordWebhook == "" then
        return
    end

    local playerName = GetPlayerName(source) or "Unknown Player"
    local playerIdentifier = GetPlayerIdentifier(source, 0) or "N/A"
    local locData = Config.Locations[locKey]
    local locLabel = locData and locData.label or (locKey or "Unknown Location")

    local title = "📺 Paddock TV State Updated"
    local color = 3447003 -- Blue

    if action == 'play' then
        title = "▶️ TV Stream Started"
        color = 5763719 -- Green
    elseif action == 'stop' then
        title = "⏹️ TV Turn Off / Cleared"
        color = 15548997 -- Red
    elseif action == 'pause' then
        title = "⏸️ TV Stream Paused"
        color = 16705372 -- Yellow
    elseif action == 'resume' then
        title = "▶️ TV Stream Resumed"
        color = 3447003 -- Blue
    elseif action == 'volume' then
        title = "🔊 TV Volume Adjusted"
        color = 10181046 -- Purple
    end

    local scopeText = ("Single TV (#%d)"):format(targetTvId)
    if scope == 'all' then
        scopeText = "Global Sync (All 7 TVs)"
    elseif scope == 'group' then
        scopeText = (groupId == 1) and "Left Bar (TV 1-4)" or "Right Bar (TV 5-7)"
    end

    local embedFields = {
        { ["name"] = "👤 Player", ["value"] = ("%s (ID: %s)"):format(playerName, tostring(source)), ["inline"] = true },
        { ["name"] = "📍 Location", ["value"] = locLabel, ["inline"] = true },
        { ["name"] = "🎯 Target Scope", ["value"] = scopeText, ["inline"] = true },
        { ["name"] = "⚡ Action", ["value"] = tostring(action):upper(), ["inline"] = true }
    }

    if action == 'play' and url and url ~= "" then
        table.insert(embedFields, { ["name"] = "🔗 YouTube URL", ["value"] = url, ["inline"] = false })
    elseif action == 'volume' and volume then
        table.insert(embedFields, { ["name"] = "🔊 Volume Level", ["value"] = ("%d%%"):format(volume), ["inline"] = true })
    end

    local embedObj = {
        ["title"] = title,
        ["color"] = color,
        ["fields"] = embedFields,
        ["footer"] = {
            ["text"] = "bazq - rs_paddock_tv",
        },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    if action == 'play' and url and url ~= "" then
        local videoId = string.match(url, "v=([%w_%-]+)") or string.match(url, "youtu%.be/([%w_%-]+)")
        if videoId then
            embedObj["image"] = { ["url"] = "https://img.youtube.com/vi/" .. videoId .. "/mqdefault.jpg" }
        end
    end

    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = Config.DiscordBotName or "bazq Paddock TV",
        avatar_url = Config.DiscordBotAvatar or "",
        embeds = { embedObj }
    }), { ['Content-Type'] = 'application/json' })
end

-- Update TV state per location and broadcast to all players (Multi-scope support)
RegisterNetEvent('rs_paddock_tv:server:updateState', function(data)
    local src = source
    
    local locKey = data.locationKey or GetPlayerLocationKey(src)
    if not locKey or not Config.Locations[locKey] then
        TriggerClientEvent('rs_paddock_tv:client:showNotification', src, _L('not_near_tv'), 'error')
        return
    end

    -- Permission Check
    if not Framework.HasPermission(src) then
        TriggerClientEvent('rs_paddock_tv:client:showNotification', src, _L('no_permission'), 'error')
        return
    end

    if not data or not data.action then return end

    local scope = data.targetScope or data.scope or 'single'
    local targetTvId = tonumber(data.tvId) or 1
    local groupId = tonumber(data.groupId) or 1

    dbg(("Player #%s triggered action -> Location: %s | Action: %s | Scope: %s | TV ID: %d | Group: %d"):format(src, locKey, tostring(data.action), tostring(scope), targetTvId, groupId))

    if scope == 'all' then
        for tvId = 1, 7 do
            if Config.TVs[tvId] then
                ApplyStateToTV(locKey, tvId, data)
            end
        end
    elseif scope == 'group' then
        local groupConfig = Config.TVGroups and Config.TVGroups[groupId]
        local targetTvIds = groupConfig and groupConfig.tvIds or ((groupId == 1) and {1, 2, 3, 4} or {5, 6, 7})
        for _, tvId in ipairs(targetTvIds) do
            if Config.TVs[tvId] then
                ApplyStateToTV(locKey, tvId, data)
            end
        end
    else
        ApplyStateToTV(locKey, targetTvId, data)
    end

    -- Trigger Discord Webhook Log Notification
    SendDiscordLog(src, locKey, scope, targetTvId, groupId, data.action, data.url, data.volume)
end)
