Config = {}

-- =============================================================================
-- 1. GENERAL & LANGUAGE SETTINGS
-- =============================================================================
Config.Debug = true                     -- Enable console debug prints (dbg() helper)
Config.Locale = 'en'                    -- Active language: 'en', 'tr', 'de', 'es', 'fr', 'pt', 'it' (Default: 'en')

-- =============================================================================
-- 2. DISCORD WEBHOOK LOGGING
-- =============================================================================
Config.DiscordLogs = true               -- Enable/Disable Discord webhook log notifications
Config.DiscordWebhook = ""              -- Paste your Discord Webhook URL here
Config.DiscordBotName = "Paddock TV"
Config.DiscordBotAvatar = "https://i.imgur.com/8N69c45.png"

-- =============================================================================
-- 3. PERMISSIONS & ACCESS CONTROL
-- =============================================================================
Config.Permissions = {
    -- Master Toggle: Setting to true allows EVERY player to use TV (bypasses all job/admin/item restrictions)
    EveryoneCanControl = true,

    -- Logic Match Mode:
    -- 'OR'  => Satisfying ANY active condition is enough (e.g. Player has Mechanic Job OR has Remote Item)
    -- 'AND' => MUST satisfy ALL active enabled conditions (e.g. Player MUST have Mechanic Job AND Remote Item)
    MatchMode = 'OR',
    
    -- Admin / Staff Permission Toggle
    RequireAdmin = false,
    AdminGroups = {
        'admin',
        'superadmin',
        'god'
    },
    
    -- Job / Profession Permission Toggle
    RequireJob = false,
    Jobs = {
        ['mechanic'] = 0,               -- Job name and minimum grade required
        ['cardealer'] = 0,
        ['paddock_staff'] = 0
    },

    -- Gang Permission Toggle (QBCore / Qbox / Devix)
    RequireGang = false,
    Gangs = {
        ['lostmc'] = 0,                 -- Gang name and minimum grade required
        ['ballas'] = 0
    },

    -- Required Item Toggle
    RequireItem = false,
    ItemName = 'tv_remote',             -- Required item identifier
    ItemCount = 1,                      -- Minimum item quantity required
    InventorySystem = 'auto',           -- 'auto', 'ox_inventory', 'qb-inventory', 'esx', 'devix-inventory', 'custom'

    -- CitizenID / Whitelist Identifiers Toggle
    RequireCitizenId = false,
    AllowedCitizenIds = {
        'AB123456',
        'CD789012'
    }
}

-- Custom Item Check Function (Runs when InventorySystem = 'custom')
Config.CustomItemCheck = function(source, itemName, itemCount)
    -- Insert custom inventory export check here if needed
    return true
end

-- Target & Input Framework Detection ('auto' detects framework automatically)
Config.TargetSystem = 'auto'            -- 'auto', 'ox_target', 'qb-target'
Config.InputSystem = 'auto'             -- 'auto', 'ox_lib', 'qb-input', 'keyboard'

-- Chat Command Support & Custom Command Names
Config.EnableCommands = true            -- Enable or disable chat commands (/tvmenu, /tvplay, etc.)
Config.Commands = {
    menu = 'tvmenu',                     -- Command to open TV Control Panel
    play = 'tvplay',                     -- Command to start video feed (/tvplay [tvId] [url])
    stop = 'tvstop',                     -- Command to stop video feed (/tvstop [tvId])
    volume = 'tvvolume'                  -- Command to set volume (/tvvolume [tvId] [0-100])
}

-- =============================================================================
-- 4. AUDIO, DISTANCE & RENDER SETTINGS
-- =============================================================================
Config.InteractDistance = 6.0           -- Target interaction distance (meters)
Config.MaxRenderDistance = 25.0         -- Audio cutoff distance (meters)
Config.DefaultVolume = 30               -- Initial volume level (0 to 100)
Config.DefaultUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
Config.DuiWidth = 1280                  -- DUI resolution width
Config.DuiHeight = 720                  -- DUI resolution height

-- =============================================================================
-- 5. STREAM PRESETS LIST (PRE-LOADED VIDEOS)
-- =============================================================================
Config.Presets = {
    {
        id = 'preset_f1',
        title = 'Formula 1 Live',
        desc = 'F1 Official Broadcast & Highlights',
        url = 'https://www.youtube.com/watch?v=kYJv8y_3Wb8'
    },
    {
        id = 'preset_gt',
        title = 'GT World Challenge',
        desc = 'Live GT3 & GT4 Race Streams',
        url = 'https://www.youtube.com/watch?v=F3t2pXnB32s'
    },
    {
        id = 'preset_lofi',
        title = 'Paddock Lo-Fi',
        desc = 'Chill radio for paddock garage',
        url = 'https://www.youtube.com/watch?v=jfKfPfyJRdk'
    },
    {
        id = 'preset_supercar',
        title = 'Supercars Sound',
        desc = 'Pure exhaust sounds compilation',
        url = 'https://www.youtube.com/watch?v=sO7z9x4h3o0'
    },
    {
        id = 'preset_drift',
        title = 'Drift Championship',
        desc = 'Drift Masters Highlights',
        url = 'https://www.youtube.com/watch?v=1F3d1wS4f5I'
    }
}

-- =============================================================================
-- 6. PADDOCK MAP LOCATIONS (5 MLO COORDINATES)
-- =============================================================================
Config.Locations = {
    ["rs_paddock_def"] = {
        label = "RS Paddock // Del Pierro",
        coords = vector3(-2202.1, -392.147, 15.0792),
        radius = 50.0
    },
    ["rs_paddock_dock"] = {
        label = "RS Paddock // Autopia Parkway",
        coords = vector3(-427.033, -2177.26, 10.4944),
        radius = 50.0
    },
    ["rs_paddock_lh"] = {
        label = "RS Paddock // Light House",
        coords = vector3(3296.77051, 5195.473, 20.8722019),
        radius = 50.0
    },
    ["rs_paddock_paleto"] = {
        label = "RS Paddock // Great Ocean Highway // Paleto",
        coords = vector3(1418.66333, 6583.02734, 16.663002),
        radius = 50.0
    },
    ["rs_paddock_sandy"] = {
        label = "RS Paddock // Alamo Sea // North Calafia Way",
        coords = vector3(737.417, 4169.41, 42.4905),
        radius = 50.0
    }
}

-- =============================================================================
-- 7. ADVANCED MODEL & TEXTURE DEFINITIONS (DO NOT EDIT UNLESS NEEDED)
-- =============================================================================
Config.SharedTxdName = "rs_paddock_tvapp_txd"

Config.TVs = {
    [1] = { name = "TV #1 (Left Bar)", model = "rs_paddock_tv_app1", txd = Config.SharedTxdName, txn = "rs_paddock_tvapp1", entitySet = "rs_paddock_tv_app1", group = 1 },
    [2] = { name = "TV #2 (Left Bar)", model = "rs_paddock_tv_app2", txd = Config.SharedTxdName, txn = "rs_paddock_tvapp2", entitySet = "rs_paddock_tv_app2", group = 1 },
    [3] = { name = "TV #3 (Left Bar)", model = "rs_paddock_tv_app3", txd = Config.SharedTxdName, txn = "rs_paddock_tvapp3", entitySet = "rs_paddock_tv_app3", group = 1 },
    [4] = { name = "TV #4 (Left Bar)", model = "rs_paddock_tv_app4", txd = Config.SharedTxdName, txn = "rs_paddock_tvapp4", entitySet = "rs_paddock_tv_app4", group = 1 },
    [5] = { name = "TV #5 (Right Bar)", model = "rs_paddock_tv_app5", txd = Config.SharedTxdName, txn = "rs_paddock_tvapp5", entitySet = "rs_paddock_tv_app5", group = 2 },
    [6] = { name = "TV #6 (Right Bar)", model = "rs_paddock_tv_app6", txd = Config.SharedTxdName, txn = "rs_paddock_tvapp6", entitySet = "rs_paddock_tv_app6", group = 2 },
    [7] = { name = "TV #7 (Right Bar)", model = "rs_paddock_tv_app7", txd = Config.SharedTxdName, txn = "rs_paddock_tvapp7", entitySet = "rs_paddock_tv_app7", group = 2 }
}

Config.TVGroups = {
    [1] = { id = 1, name = "Left Bar (TV 1-4)", tvIds = { 1, 2, 3, 4 } },
    [2] = { id = 2, name = "Right Bar (TV 5-7)", tvIds = { 5, 6, 7 } }
}

Config.RemoteModels = {
    'prop_tv_remote',
    'v_res_tre_remote'
}

Config.TVModels = {
    'rs_paddock_tv_app1',
    'rs_paddock_tv_app2',
    'rs_paddock_tv_app3',
    'rs_paddock_tv_app4',
    'rs_paddock_tv_app5',
    'rs_paddock_tv_app6',
    'rs_paddock_tv_app7'
}
