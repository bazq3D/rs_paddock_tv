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
-- 2.1 RETRO STORE RADIO INTEGRATION (rs_radio)
-- =============================================================================
Config.UseRsRadio = true                -- Auto-create static emitters for Paddock TV locations via rs_radio if started
Config.RsRadio = {
    stationId = "south",                 -- Radio station ID configured on your rs_radio server resource
    radius = 25.0,                       -- Audio falloff radius (5.0 .. 250.0)
    volume = 0.4,                        -- Radio volume (0.0 .. 1.0)
    interiorOnly = true,                 -- Muffle audio outside interior
    enabled = true                       -- Start switched on (default: true)
}

-- =============================================================================
-- 2.2 RETRO STORE WEATHER DISASTER INTEGRATION (rs_weather Emergency Broadcast)
-- =============================================================================
Config.UseRsWeatherDisaster = true      -- Auto-broadcast emergency warning on all TVs when a disaster starts in rs_weather
Config.RsWeatherDisaster = {
    -- Emergency Warning Stream URL played across all TVs during a disaster (e.g. Tsunami / Tornado Siren)
    EmergencyUrl = 'https://www.youtube.com/watch?v=xeXD7t16v8s',
    Volume = 100,                        -- Emergency broadcast volume level (0 to 100, default: 100 max volume)
    RestorePreviousState = true          -- Automatically restore previous stream states when the disaster ends
}

-- =============================================================================
-- 2.3 RETRO STORE WEATHER CHANNEL TV BROADCAST INTEGRATION
-- =============================================================================
Config.UseWeatherChannel = true         -- Enable RS Weather Channel stream on Paddock TVs
Config.WeatherChannelTvId = 1           -- Default TV ID to play Weather Channel broadcast when idle (1..7, default: 1)
Config.WeatherChannelSettings = {
    stationName = "RS WEATHER",
    tagline = "PADDOCK LOCAL FORECAST",
    cycleSeconds = 12,
    refreshSeconds = 10
}

-- =============================================================================
-- 2.4 RETRO STORE RADIO STATION VISUALIZER TV INTEGRATION
-- =============================================================================
Config.UseRsRadioChannel = true        -- Enable RS Radio Animated Visualizer Channel on Paddock TVs
Config.RsRadioTvId = 7                 -- Default TV ID to play RS Radio Visualizer Channel when idle (1..7, default: 7)
Config.RsRadioSettings = {
    -- List of custom background scenery image URLs or local file paths for the Radio visualizer background
    SceneryImages = {
        "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1280", -- Beach Sunset
        "https://images.unsplash.com/photo-1519681393784-d120267933ba?q=80&w=1280", -- Mountain Night Sky
        "https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1280", -- Yosemite Valley
        "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=1280"  -- Foggy Mountain Forest
    },
    SceneryIntervalSeconds = 12         -- Time interval between scenery image transitions (seconds)
}

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
Config.MuteDuplicateAudio = true        -- Automatically mute duplicate audio when multiple TVs play the same stream (prevents audio echo/overlap)
Config.DefaultUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
Config.DuiWidth = 1280                  -- DUI resolution width
Config.DuiHeight = 720                  -- DUI resolution height

-- =============================================================================
-- 5. PADDOCK MAP LOCATIONS (5 MLO COORDINATES)
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
