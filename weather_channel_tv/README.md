# RS Weather Channel — TV page

A standalone weather-channel broadcast page for FiveM TV apps. Three files, no
dependencies:

```
index.html
style.css
app.js
```

It cycles through every weather region on the server showing current
conditions, temperatures, and the upcoming forecast, with a scrolling ticker.
When an RS Weather disaster (tsunami/tornado) is armed or running it switches
to an EAS-style red alert presentation automatically.

## Requirements

The server must run **rs_weather** (v2.1.0+), which exposes the read-only feed
this page plugs into:

```
http://<server-ip>:30120/rs_weather/channel/data
```

No auth, no control surface, CORS is open — safe to call from any NUI/DUI.

## Hooking it into your TV app

Add the three files to your resource (and its `files { ... }` list) and render
`index.html` in your TV's DUI/NUI browser. Then feed it data one of two ways:

### Option A — let the page poll (easiest)

Open `app.js` and set the feed URL at the top:

```js
const SETTINGS = {
  dataUrl: "http://YOUR_SERVER_IP:30120/rs_weather/channel/data",
  ...
};
```

The page polls it every 10 seconds and handles everything else itself.

### Option B — your script pushes the data

Leave `dataUrl` empty, fetch the feed in your own Lua, and forward it:

```lua
CreateThread(function()
    while true do
        PerformHttpRequest('http://127.0.0.1:30120/rs_weather/channel/data', function(status, body)
            if status == 200 and body then
                SendNUIMessage({ type = 'rsweather:channel:data', data = json.decode(body) })
            end
        end, 'GET')
        Wait(10000)
    end
end)
```

You can also reconfigure the page at runtime:

```lua
SendNUIMessage({
    type = 'rsweather:channel:config',
    stationName = 'WZL',
    tagline = 'YOUR LOCAL FORECAST',
    cycleSeconds = 12,
    refreshSeconds = 10
})
```

## Previewing without a server

Open `index.html` in any browser. With no reachable feed it runs a built-in
demo loop (badged "DEMO FEED"). Add `?alert` to the URL — or set
`demoAlert: true` in `app.js` — to preview the disaster alert presentation.

## Notes

- All sizing is viewport-relative, so it scales to any TV texture resolution.
- Forecast rows show the approximate **in-game** arrival time; segments too
  far out to map onto the clock fall back to a real-minute countdown (`+34m`).
- Station branding, cycle speed, and forecast length can also be set
  server-side in rs_weather's `Config.WeatherChannel`; values from the feed
  win over the SETTINGS defaults.
