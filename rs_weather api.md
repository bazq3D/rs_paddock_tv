# RS Weather Developer API

Weather API version: `1.0.0` (resource version `1.9.0`)

All authoritative weather control exports must be called from a server script. Client exports only affect the local player. Weather names are case-insensitive and common aliases such as `sunny` and `fog` are normalized.

Supported weather types are `EXTRASUNNY`, `CLEAR`, `CLOUDS`, `SMOG`, `FOGGY`, `OVERCAST`, `RAIN`, `THUNDER`, `CLEARING`, `NEUTRAL`, `SNOW`, `BLIZZARD`, `SNOWLIGHT`, `XMAS`, and `HALLOWEEN`.

## Server queries

```lua
local version = exports.rs_weather:GetApiVersion()
local state = exports.rs_weather:GetWeatherState()
local regions = exports.rs_weather:GetRegions()
local region, err = exports.rs_weather:GetRegionWeather('los_santos')
local forecast, err = exports.rs_weather:GetRegionForecast('los_santos')
local schedule, err = exports.rs_weather:GetRegionSchedule('los_santos')
local valid, normalized = exports.rs_weather:IsValidWeather('thunder')
local frozen = exports.rs_weather:IsWeatherFrozen()
```

Returned state tables are copies and may be safely modified by the calling resource.

## Regional and global control

```lua
local ok, result = exports.rs_weather:SetRegionWeather('sandy', 'RAIN', {
    durationMinutes = 20,
    transitionSeconds = 8
})

exports.rs_weather:ClearRegionWeather('sandy', { transitionSeconds = 8 })

exports.rs_weather:SetGlobalWeather('THUNDER', {
    durationMinutes = 10,
    transitionSeconds = 5
})

exports.rs_weather:ClearGlobalWeather({ transitionSeconds = 10 })
exports.rs_weather:SetWeatherFrozen(true)
```

`SetRegionSchedule(region, steps)` uses the same persistent schedule format as `data/weather_patterns.json`:

```lua
local ok, result = exports.rs_weather:SetRegionSchedule('paleto', {
    { weather = 'CLOUDS', durationMin = 45, temp = 62 },
    { weather = 'RAIN', durationMin = 30, temp = 57 }
})
```

Existing blackout exports remain available: `SetRegionBlackout`, `GetRegionBlackout`, `GetRegionBlackouts`, `SetCitywideBlackout`, `GetCitywideBlackout`, and `GetCitywideBlackoutSource`.

## Natural disasters

The disaster controller is server-authoritative and permits one active or armed
run at a time. The production types are `tsunami` and `tornado`; hurricane is
intentionally not shipped in this release. Both types use absolute server
timestamps so the admin Forecast Overlay and in-world presentation derive from
the same synchronized state.

Tsunami phase weather is intentionally applied to every configured region so
the restart event remains synchronized across the whole map. Tornado phase
weather is applied only to the route's `affectedRegion`. Both paths preserve
the previous per-region overrides and restore only overrides that still match
the disaster's lease; a newer admin or resource override is never cleared by
disaster cleanup.

```lua
local disaster = exports.rs_weather:GetDisasterState()
local active = exports.rs_weather:IsDisasterActive()

local ok, stateOrError = exports.rs_weather:StartDisaster('tsunami', {
    preset = 'standard',
    source = 'my_resource'
})

if ok then
    exports.rs_weather:StopDisaster('event_finished', stateOrError.runId)
end
```

To start the default Grand Senora/Sandy Shores tornado route:

```lua
local ok, stateOrError = exports.rs_weather:StartDisaster('tornado', {
    preset = 'standard',
    routeId = 'sandy_desert',
    source = 'my_resource'
})
```

Custom tornado routes must provide matching point-for-point world and admin-map
tracks. The server copies the world track's seeded timing onto the map track so
the in-game funnel and Forecast Overlay marker remain synchronized:

```lua
local ok, stateOrError = exports.rs_weather:StartDisaster('tornado', {
    preset = 'standard',
    route = {
        id = 'custom_sandy_track',
        affectedRegion = 'sandy',
        geography = 'mainland', -- optional; otherwise derived from affectedRegion
        worldPath = {
            { x = -1200.0, y = 2750.0, z = 55.0 },
            { x = 250.0, y = 3180.0, z = 43.0 }
        },
        mapPath = {
            { x = 340.0, y = 448.0 },
            { x = 475.0, y = 414.0 }
        }
    }
})
```

Both arrays require at least two valid points and must have equal lengths.
Incomplete custom/configured routes return stable errors:
`tornado_route_world_path_required`, `tornado_route_map_path_required`, or
`tornado_route_path_length_mismatch`. Invalid coordinates return
`tornado_route_world_point_invalid` or `tornado_route_map_point_invalid`. A
non-table configured definition returns `invalid_tornado_route_definition`, and
an unknown route ID returns `invalid_tornado_route`. A world-only route is
rejected rather than rendered at the wrong place (or invisibly) in the admin
map.

Shipped presets are `test`, `standard`, and `severe`. A hurricane request
returns `false, 'hurricane_retired_unsupported'`; it is never converted into a
different disaster. Other unknown names return `false, 'invalid_type'`.

The state lifecycle is `idle`, `armed`, `running`, `paused`, and `recovering`.
`armed` is preview/scheduling state only; live weather, water, and world visuals
begin when the event enters `running` (or when a txAdmin-linked arm is started by
its restart timeline).
The state payload includes `revision`, `runId`, `type`, `preset`, `phase`,
`effects`, `metrics`, `visual`, and `catalog`. Every visual declares
`visual.geography` (`mainland` or `cayo`) so the combined map can route it to
the correct geography layer and weather scope. Disaster definitions may set
`geography` explicitly or target the `cayo` region. A definition without either
may resolve to Cayo only when every supplied world-path point lies inside
`Config.ZoneCayoWorldBounds`; 2D `mapPath` coordinates are never used for this
decision. Legacy, mixed-region, missing, and ambiguous values remain on
`mainland`. Tsunami state includes calibrated coast paths. Tornado state includes
matching timestamped `visual.mapPath`,
`visual.worldPath`/`tornadoWorldPath`, `visual.current`, radius, height,
intensity, force multiplier, route seed, and affected region.

Tsunami `effects.water.startLevel` and `endLevel` are synchronized rise offsets
in metres above sea level. In the default `owned_xml` mode, each client loads
RS Weather's `water/rs_weather_flood.xml` through `LoadWaterFromPath`. GTA normalizes that
authored plane into a 500 m render grid; RS Weather preserves those generated
bounds and raises every visible grid chunk to `referenceSeaLevel + rise`. The
shipped grid covers the playable envelope from `(-4000, -4000)` to
`(4500, 8000)`. The file is declared in `fxmanifest.lua` and must remain in the
installed resource. Loading and raising the water are client-local operations
driven by the same server timestamps, so every client receives the same target
height without networked water entities.

`LoadWaterFromPath` temporarily replaces that client's complete water
definition. On cleanup, RS Weather loads `baselineFile`/`restoreFile` when one is
configured; otherwise it calls the void `ResetWater` native once to restore
GTA's default water, then releases its local ownership state. Run only one
resource that owns or replaces runtime water definitions. The legacy
`ModifyWater` fallback uses the native argument order
`x, y, radius, height`.

The coast presentation uses the stock GTA V Legacy
`core/wtr_rocks_rnd_splash` effect, so no streamed storm models are required.
The splash field migrates inland with the synchronized water rise.

During a real flood, `cl_disaster_tsunami_buoyancy.lua` checks water contact at
each nearby vehicle hull before applying bounded buoyancy, current, drag, and
righting forces. It does not change global gravity or hard-set vehicle velocity,
and a client mutates a networked vehicle only while it owns that entity.

Runtime-loaded water quads can occasionally report their correct surface while
GTA misses the local player's swimming state. The tsunami player-water
controller independently confirms that the player is below the active flood
surface and restores GTA's native swimming flag. GTA owns movement, breath
depletion, and drowning whenever the engine recognizes the runtime water.
Interior players are excluded by default, and separate enter/release depths
prevent wave motion from repeatedly toggling the compatibility state.
The controller snapshots config flags 65 (`IsSwimming`) and 3
(`DrownsInWater`) before intervention and restores both when the player exits
the flood, the event ends, or the resource stops. A written flag is not reported
as success by itself: `nativeSwimmingConfirmed` becomes true only when GTA's
`IS_PED_SWIMMING` native confirms that the engine accepted the water state.
`nativeUnderwaterConfirmed` and `nativeBreathConfirmed` provide the stricter
runtime proof for drowning: the latter is set only after GTA reports decreasing
underwater time. If the current artifact still refuses to consume native breath,
the configurable fallback starts only after the local player's head remains
below the measured flood surface for `fallbackNativeGraceMs`. It then consumes
its own oxygen timer before applying small, capped GTA ped-damage ticks that can
eventually drown the player but cannot instantly kill a healthy ped. Entering a
vehicle/interior, raising the head, ending the tsunami, or stopping the resource
clears that timer immediately. Native breath confirmation permanently suppresses
the fallback for that submersion.

The tornado is a terrain-snapped, moving local hazard. Its visual composition
uses layered stock GTA dust-devil, ground-debris, foundry-dust, and smoke PTFX;
there are no streamed tornado models. Clients derive movement from the server
route and clock, use distance-based visual LOD, and apply bounded tangential,
inward, and lift forces only to nearby owned vehicles, peds, and eligible loose
objects. The default route is `sandy_desert`. Tornadoes are manual events and
cannot be attached to txAdmin restart scheduling.

Server resources may also listen for:

```lua
AddEventHandler('rs-weather:disasterStarted', function(state) end)
AddEventHandler('rs-weather:disasterPhaseChanged', function(state) end)
AddEventHandler('rs-weather:disasterStopped', function(state) end)
```

The administrator command is:

```text
rsdisaster status
rsdisaster arm tsunami standard
rsdisaster arm tsunami standard global_coasts txadmin
rsdisaster start tsunami test
rsdisaster jump rain_build
rsdisaster jump storm_surge
rsdisaster arm tornado standard sandy_desert
rsdisaster start tornado test sandy_desert
rsdisaster jump touchdown
rsdisaster jump peak
rsdisaster pause
rsdisaster resume
rsdisaster cancel
```

`jump` accepts a phase name or one-based phase index. It advances or rewinds the
same authoritative run timeline, including its coast paths and water interpolation;
it does not create a separate client-only state. Phase jumping is intentionally
unavailable for txAdmin-linked runs so a scheduled restart cannot be desynced.

The **Disaster Control** panel exposes both production types, their routes and
presets, phase jumping, and a local visual preview. Tsunami preview loads the
owned flood XML and ramps the editing admin's local water to the Test target of
`+26 m`; tornado preview places the layered funnel near that admin. Clearing,
replacing, or expiring a preview restores its local state. A preview never
changes authoritative disaster state or another player.

Useful client-only visual diagnostics are:

```text
rsweatherptfxpreview tsunami [distance]
rsweatherptfxpreview status
rsweatherptfxpreview clear
rsweatherptfxstatus
rsweatherwaterdiag
rsweatherwaterpreview start 26 45
rsweatherwaterpreview status
rsweatherwaterpreview clear
rsweathertornadopreview start 180 90
rsweathertornadopreview status
rsweathertornadopreview stop
rsweathertornadodiag
rsweathertsunamivehiclediag
rsweathertsunamiplayerdiag
```

`rsweatherwaterpreview` is client-local and refuses to start while a
server-authoritative disaster is active. Its first number is rise in metres and
its second is duration in seconds.

Client resources can inspect the same diagnostics through
`GetTsunamiWorldVisualStatus`, `GetDisasterWaterStatus(includeProbes)`,
`GetTsunamiVehicleBuoyancyStatus`, `GetTsunamiPlayerWaterStatus`,
`GetTornadoVisualStatus`, and
`GetDisasterPtfxRegistryStatus`.

For txAdmin, arm a tsunami with the `txadmin_restart` trigger from Disaster
Control. The controller listens for scheduled-restart, skipped-restart, and
shutdown events without requiring txAdmin as a hard resource dependency.
txAdmin scheduling is deliberately rejected for tornadoes.

## Map calibration anchors

Map Calibration is a developer-only workspace inside the admin panel. It can
capture a developer's exact GTA `x/y/z`, then pair it with a clicked location
on the combined Top Down map. Records are persisted with
`control` or `holdout` roles and a monotonically increasing revision. The
captured current-projection point is retained as evidence, but calibration
tools fit against the developer's observed map point instead.

Normal framework admins and holders of `rsweather.admin` do not see this
workspace or receive its saved anchors. The player must have ordinary weather
admin access **and** the separate developer ACE:

```cfg
add_ace identifier.license:YOUR_LICENSE_HERE rs_weather.developer.calibration allow
```

The built-in workflow is:

```text
/rsweatheradmin
Debug > Map Calibration > Capture My XYZ > tap the matching map landmark
```

The equivalent capture command is:

```text
/rsweather_captureanchor cayo
```

Server resources can read a defensive copy of the current document:

```lua
local calibration = exports.rs_weather:GetCalibrationAnchors()
-- calibration.revision
-- calibration.anchors[i].world = { x, y, z }
-- calibration.anchors[i].map = { x, y }
-- calibration.anchors[i].role = 'control' or 'holdout'
-- calibration.anchors[i].verification.serverPositionVerified
```

The server export above is for trusted server resources; it does not grant a
network client access to the calibration store. Returned map points use the expanded combined-display coordinate space,
not the old standalone Cayo inset. The built-in UI links each map click to its
pending capture token; the server independently enforces both admin and
developer permission, geography/world bounds, current-position verification,
and revision checks.
No saved anchor automatically changes the production map transform.

**Copy Anchor JSON** emits the complete
`rs_weather.map3d.cayo_anchor_calibration` solver document. Its fixed projection
fields match `tools/map3d/cayo/cayo_anchor_calibration.template.json`; only the
persisted anchor array varies. Run `tools/map3d/cayo/solve_cayo_anchor_calibration.py`
to produce a similarity fit, an affine-stretch diagnostic, control/holdout
residuals, coverage gates, and a separate Z summary.

## Private player weather

Server resources can assign weather to one player without changing any region or other client:

```lua
local ok, override = exports.rs_weather:SetPlayerWeather(playerSource, 'RAIN', {
    durationSeconds = 300,
    transitionSeconds = 4,
    notify = false
})

exports.rs_weather:ClearPlayerWeather(playerSource)
```

When `durationSeconds` is omitted, the override remains until its owning resource clears it. Overrides are owned by the calling resource. If multiple resources assign weather, the newest active override is displayed; clearing it reveals the previous one.

`ClearPlayerWeather` clears only the calling resource's assignment. `ClearAllPlayerWeather` is an explicit administrative cleanup. `GetPlayerWeatherOverride` returns the effective server-managed assignment.

Client resources can assign weather only to their own client:

```lua
local ok, override = exports.rs_weather:SetLocalWeather('FOGGY', {
    durationSeconds = 120,
    transitionSeconds = 3
})

local current = exports.rs_weather:GetLocalWeatherOverride()
exports.rs_weather:ClearLocalWeather()
```

Players are not given a built-in command or UI for private weather. A developer resource decides when to call these exports. Private weather changes visuals and rain/snow effects while RS Weather continues synchronizing time and regional state underneath it.

The Forecast phone app displays private weather as the current condition while retaining the authoritative regional forecast and temperatures. Set `notify = true` to request a Forecast notification; player notification preferences can still suppress it.

## RTX Housing integration

The optional RTX Housing bridge uses the documented
`rtx_housing:Global:EnterProperty` and
`rtx_housing:Global:ExitProperty` client events as wake-up signals, then queries
`exports['rtx_housing']:IsPlayerInsideProperty()` for authoritative state. It
suppresses weather only when that export returns `inside == true` and
`insideType == 'inside'`; it never uses the broader property-zone result that
also includes yards.

The integration is configured at `Config.Integrations.RtxHousing`. Its resource
name, polling/recheck intervals, unknown-type behavior, and `SHELL`/`IPL`/`MLO`
suppression can be changed without editing RTX Housing. It is an optional
dependency and fails open when the configured resource is not running.

Client resources can inspect the shared state:

```lua
local blocked = exports.rs_weather:IsHousingInteriorActive()
local state = exports.rs_weather:GetHousingInteriorState()
-- state.enabled, state.available, state.blocked, state.inside
-- state.insideType, state.propertyId, state.propertyType, state.resource
-- state.reason, state.lastError, state.lastRefreshAtMs
```

Client resources in the same runtime can also listen for a transition:

```lua
AddEventHandler('rs-weather:housingInteriorChanged', function(blocked, state)
    -- `blocked` is true only for a configured indoor property type.
end)
```

An active housing interior feeds RS Weather's existing `IsSyncDisabled()`
client export. Outdoor weather/disaster presentation is cleared, but the
authoritative clock continues to apply. Suppression is source-owned: leaving a
house does not re-enable weather while another integration or explicit sync
disable still owns the block.

## Events

Server resources may listen for:

```lua
AddEventHandler('rs-weather:regionChanged', function(payload)
    -- payload.region, payload.current, payload.next, payload.eta
end)

AddEventHandler('rs-weather:playerOverrideChanged', function(payload)
    -- payload.action: set, cleared, expired, or cleared_all
end)
```

## Return values

Control exports return `success, resultOrError`. Common errors are
`invalid_player`, `invalid_region`, `region_disabled`, `invalid_weather`,
`invalid_duration`, `invalid_transition`, `invalid_schedule`, `no_regions`,
`invalid_type`, and `unsupported_disaster_type`.
