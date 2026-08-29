# 🏁 rs_paddock_tv (by bazq)

Multi-Screen Independent YouTube DUI Sync TV System created for Paddock MLO maps in FiveM.

---

## 🌟 Features

- **7-Screen Matrix MLO Support:** Controls 7 TV screens across Left Bar (TV 1-4) and Right Bar (TV 5-7).
- **Per-Location Isolation:** Supports up to 5 Paddock locations independently. Actions at one location do NOT affect TVs at other locations.
- **Broadcast Scopes:**
  - **Single Scope:** Control an individual TV screen.
  - **Group Scope:** Control Left Bar (TV 1-4) or Right Bar (TV 5-7) simultaneously.
  - **Global Scope:** Control all 7 TVs at your current location at once.
- **Real-Time YouTube Sync:** Synchronizes video playback, time offset, and state across all players.
- **Dynamic 3D Audio & MLO EntitySet Sync:** Volume decreases smoothly with distance (up to 25m). TV lights and screen entity sets toggle dynamically (`rs_paddock_tv_app1..7`).
- **Universal Framework Support:** Built-in auto-detection for `qb-core`, `qbox`, `es_extended`, `ox_core`, and `devix-core`.
- **Full Inventory Integration:** Auto-detects `ox_inventory`, `qb-inventory`, `esx`, `devix-inventory`, and custom items.
- **Target Systems:** Auto-detects `ox_target` and `qb-target`.
- **Escrow-Ready & Open Source:** Full source code unlocked. Detailed `config.lua` options for permissions (Admin, Job, Gang, Item, Whitelist, MatchMode).

---

## 📥 Installation

1. Download or clone `rs_paddock_tv` into your FiveM server resources folder:
   ```text
   resources/[retrostore]/rs_paddock_tv
   ```
2. Ensure the resource in your `server.cfg`:
   ```cfg
   ensure rs_paddock_tv
   ```
3. Configure `config.lua` to match your server settings.

---

## ⚙️ Configuration (`config.lua`)

The `config.lua` file is clean, organized into 7 clear sections, with easy options at the top:

```lua
-- 1. GENERAL & LANGUAGE SETTINGS
Config.Debug = true
Config.Locale = 'en'                    -- Available: 'en', 'tr', 'de', 'es', 'fr', 'pt', 'it' (Default: 'en')

-- 2. DISCORD WEBHOOK LOGGING
Config.DiscordLogs = true
Config.DiscordWebhook = "https://discord.com/api/webhooks/..."
Config.DiscordBotName = "bazq Paddock TV"
Config.DiscordBotAvatar = "https://i.imgur.com/8N69c45.png"

-- 3. PERMISSIONS & ACCESS CONTROL
Config.Permissions = {
    EveryoneCanControl = true,           -- Master Toggle
    -- 'OR'  => Satisfying ANY active condition is enough (e.g. Mechanic OR Has Remote)
    -- 'AND' => MUST satisfy ALL active conditions (e.g. Mechanic AND Has Remote)
    MatchMode = 'OR',
    
    RequireAdmin = false,
    AdminGroups = { 'admin', 'superadmin', 'god' },
    
    RequireJob = false,
    Jobs = { ['mechanic'] = 0, ['cardealer'] = 0 },

    RequireGang = false,
    Gangs = { ['lostmc'] = 0, ['ballas'] = 0 },

    RequireItem = false,
    ItemName = 'tv_remote',
    ItemCount = 1,
    InventorySystem = 'auto',

    RequireCitizenId = false,
    AllowedCitizenIds = { 'AB123456', 'CD789012' }
}

-- CHAT COMMAND TOGGLES & CUSTOM COMMAND NAMES
Config.EnableCommands = true            -- Enable or disable chat commands
Config.Commands = {
    menu = 'tvmenu',                     -- Command to open NUI panel
    play = 'tvplay',                     -- Command to play stream
    stop = 'tvstop',                     -- Command to stop stream
    volume = 'tvvolume'                  -- Command to adjust volume
}
```

---

## 🎮 Usage & Controls

### Target Interaction
- Approach any Paddock TV screen or Remote Control prop in the MLO.
- Use **ox_target** or **qb-target** to interact and click **"TV Kontrol Paneli / Control TV Panel"**.

### Chat Commands (Can be toggled via `Config.EnableCommands`)
- `/[menu_cmd] [tvId]` (default: `/tvmenu`) - Open the Master Control Room NUI panel.
- `/[play_cmd] [tvId] [youtube_url]` (default: `/tvplay`) - Play YouTube video on a specific TV.
- `/[stop_cmd] [tvId]` (default: `/tvstop`) - Turn off a specific TV.
- `/[volume_cmd] [tvId] [0-100]` (default: `/tvvolume`) - Adjust volume for a specific TV.

---

## 📄 License & Credits

- Developed by **bazq**.
- Open Source License.
