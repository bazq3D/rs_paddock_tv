Framework = {}
local core = nil
local activeFramework = 'standalone'

local function dbg(msg)
    if Config.Debug then
        print(("^4[bazq-paddock-tv] [server/framework] ^7%s"):format(msg))
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
        core = exports['qb-core']:GetCoreObject()
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

-- Admin Group Check
function Framework.CheckAdmin(source)
    if activeFramework == 'ox' then
        local player = core:GetPlayer(source)
        if player then
            for _, group in ipairs(Config.Permissions.AdminGroups) do
                if player.getGroup() == group then
                    return true
                end
            end
        end
    elseif activeFramework == 'qb' or activeFramework == 'qbox' or activeFramework == 'devix' then
        if core then
            for _, group in ipairs(Config.Permissions.AdminGroups) do
                if core.Functions.HasPermission(source, group) then
                    return true
                end
            end
        end
    elseif activeFramework == 'esx' then
        if core then
            local xPlayer = core.GetPlayerFromId(source)
            if xPlayer then
                local playerGroup = xPlayer.getGroup()
                for _, group in ipairs(Config.Permissions.AdminGroups) do
                    if playerGroup == group then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Job / Profession Check
function Framework.CheckJob(source)
    if activeFramework == 'ox' then
        local player = core:GetPlayer(source)
        if player then
            local job = player.getJob()
            if job and Config.Permissions.Jobs[job.name] then
                local minGrade = Config.Permissions.Jobs[job.name]
                if job.grade >= minGrade then
                    return true
                end
            end
        end
    elseif activeFramework == 'qb' or activeFramework == 'qbox' or activeFramework == 'devix' then
        if core then
            local player = core.Functions.GetPlayer(source)
            if player then
                local jobName = player.PlayerData.job.name
                local jobGrade = player.PlayerData.job.grade.level
                if Config.Permissions.Jobs[jobName] and jobGrade >= Config.Permissions.Jobs[jobName] then
                    return true
                end
            end
        end
    elseif activeFramework == 'esx' then
        if core then
            local xPlayer = core.GetPlayerFromId(source)
            if xPlayer then
                local jobName = xPlayer.job.name
                local jobGrade = xPlayer.job.grade
                if Config.Permissions.Jobs[jobName] and jobGrade >= Config.Permissions.Jobs[jobName] then
                    return true
                end
            end
        end
    end
    return false
end

-- Required Item Inventory Check
function Framework.CheckItem(source)
    local itemName = Config.Permissions.ItemName
    local itemCount = Config.Permissions.ItemCount
    local invSystem = Config.Permissions.InventorySystem

    if invSystem == 'auto' then
        if GetResourceState('ox_inventory') == 'started' then
            invSystem = 'ox_inventory'
        elseif GetResourceState('devix-inventory') == 'started' then
            invSystem = 'devix-inventory'
        elseif GetResourceState('qb-inventory') == 'started' or activeFramework == 'qb' or activeFramework == 'qbox' or activeFramework == 'devix' then
            invSystem = 'qb-inventory'
        elseif activeFramework == 'esx' then
            invSystem = 'esx'
        else
            invSystem = 'custom'
        end
    end

    if invSystem == 'ox_inventory' then
        local count = exports.ox_inventory:Search(source, 'count', itemName)
        if count and count >= itemCount then
            return true
        end
    elseif invSystem == 'devix-inventory' then
        local count = exports['devix-inventory']:GetItemCount(source, itemName)
        if count and count >= itemCount then
            return true
        end
    elseif invSystem == 'qb-inventory' then
        if core then
            local player = core.Functions.GetPlayer(source)
            if player then
                local item = player.Functions.GetItemByName(itemName)
                if item and item.amount >= itemCount then
                    return true
                end
            end
        end
    elseif invSystem == 'esx' then
        if core then
            local xPlayer = core.GetPlayerFromId(source)
            if xPlayer then
                local item = xPlayer.getInventoryItem(itemName)
                if item and item.count >= itemCount then
                    return true
                end
            end
        end
    elseif invSystem == 'custom' then
        if Config.CustomItemCheck then
            return Config.CustomItemCheck(source, itemName, itemCount)
        end
    end

    return false
end

-- Gang Check (QBCore / Qbox / Devix)
function Framework.CheckGang(source)
    if activeFramework == 'qb' or activeFramework == 'qbox' or activeFramework == 'devix' then
        if core then
            local player = core.Functions.GetPlayer(source)
            if player and player.PlayerData and player.PlayerData.gang then
                local gangName = player.PlayerData.gang.name
                local gangGrade = player.PlayerData.gang.grade.level or 0
                if Config.Permissions.Gangs and Config.Permissions.Gangs[gangName] then
                    if gangGrade >= Config.Permissions.Gangs[gangName] then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- CitizenID / Identifier Whitelist Check
function Framework.CheckCitizenId(source)
    local citizenId = nil
    if activeFramework == 'ox' then
        local player = core:GetPlayer(source)
        if player then citizenId = player.charid or player.stateId end
    elseif activeFramework == 'qb' or activeFramework == 'qbox' or activeFramework == 'devix' then
        if core then
            local player = core.Functions.GetPlayer(source)
            if player then citizenId = player.PlayerData.citizenid end
        end
    elseif activeFramework == 'esx' then
        if core then
            local xPlayer = core.GetPlayerFromId(source)
            if xPlayer then citizenId = xPlayer.identifier end
        end
    end

    if citizenId and Config.Permissions.AllowedCitizenIds then
        for _, id in ipairs(Config.Permissions.AllowedCitizenIds) do
            if tostring(id) == tostring(citizenId) then
                return true
            end
        end
    end
    return false
end

-- Master Permission Verifier (Evaluates MatchMode 'OR' / 'AND')
function Framework.HasPermission(source)
    -- EveryoneCanControl bypasses all checks if enabled
    if Config.Permissions.EveryoneCanControl then
        return true
    end

    -- Ace permissions override (rs_paddock_tv.admin)
    if IsPlayerAceAllowed(source, "rs_paddock_tv.admin") then
        return true
    end

    local checks = {}

    if Config.Permissions.RequireAdmin then
        table.insert(checks, Framework.CheckAdmin(source))
    end

    if Config.Permissions.RequireJob then
        table.insert(checks, Framework.CheckJob(source))
    end

    if Config.Permissions.RequireGang then
        table.insert(checks, Framework.CheckGang(source))
    end

    if Config.Permissions.RequireItem then
        table.insert(checks, Framework.CheckItem(source))
    end

    if Config.Permissions.RequireCitizenId then
        table.insert(checks, Framework.CheckCitizenId(source))
    end

    -- Default fallback deny if no check toggles are enabled
    if #checks == 0 then
        return false
    end

    local matchMode = Config.Permissions.MatchMode or 'OR'

    if matchMode:upper() == 'AND' then
        -- Requires ALL active enabled conditions to pass
        for _, passed in ipairs(checks) do
            if not passed then return false end
        end
        return true
    else
        -- Requires ANY single active condition to pass (OR)
        for _, passed in ipairs(checks) do
            if passed then return true end
        end
        return false
    end
end
