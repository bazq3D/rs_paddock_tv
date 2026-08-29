/* =========================================================================
   RS Weather Channel — standalone TV broadcast page.

   SETTINGS — edit these when embedding this page in your TV script.
   ========================================================================= */
const SETTINGS = {
  // Full URL of the RS Weather channel feed, e.g.
  //   "http://127.0.0.1:30120/rs_weather/channel/data"
  // Leave empty if your script pushes data instead (see README.md).
  dataUrl: "",

  // Fallbacks used until the feed answers (the feed's own values win).
  stationName: "RS WEATHER",
  tagline: "LOCAL FORECAST",
  cycleSeconds: 12,
  refreshSeconds: 10,

  // Set true to force the built-in demo loop (never contacts a server).
  demo: false,

  // Set true (or open the page with ?alert) to add a sample tsunami warning
  // to the demo loop, for previewing the alert presentation.
  demoAlert: false
};

(() => {
  "use strict";

  /* ---------------- weather naming / icons -------------------------------- */
  const WEATHER_NAMES = {
    EXTRASUNNY: "Extra Sunny", CLEAR: "Clear", CLEARING: "Clearing",
    CLOUDS: "Clouds", OVERCAST: "Overcast", RAIN: "Rain", THUNDER: "Thunder",
    SMOG: "Smog", FOGGY: "Foggy", SNOW: "Snow", BLIZZARD: "Blizzard",
    SNOWLIGHT: "Light Snow", XMAS: "Snow", NEUTRAL: "Neutral", HALLOWEEN: "Halloween"
  };
  const REGION_NAMES = {
    los_santos: "Los Santos", sandy: "Sandy Shores", sandy_shores: "Sandy Shores",
    paleto: "Paleto Bay", paleto_bay: "Paleto Bay",
    cayo: "Cayo Perico", cayo_perico: "Cayo Perico", roxwood: "Roxwood"
  };

  function canonical(value) {
    const raw = String(value || "CLEAR").toUpperCase();
    if (raw === "SUNNY") return "EXTRASUNNY";
    if (raw === "FOG") return "FOGGY";
    if (raw === "XMAS") return "SNOW";
    return raw;
  }
  function weatherLabel(value) {
    const raw = canonical(value);
    if (WEATHER_NAMES[raw]) return WEATHER_NAMES[raw];
    return raw.toLowerCase().replace(/[_-]+/g, " ").replace(/\b\w/g, m => m.toUpperCase());
  }
  function regionLabel(key, fallback) {
    const k = String(key || "").toLowerCase();
    if (REGION_NAMES[k]) return REGION_NAMES[k];
    const src = String(fallback || key || "Region");
    return src.replace(/[_-]+/g, " ").replace(/\b\w/g, m => m.toUpperCase());
  }
  function weatherIcon(value) {
    const w = canonical(value).toLowerCase();
    if (w.includes("thunder")) return "⛈";
    if (w.includes("rain") || w.includes("clearing")) return "\u{1F327}";
    if (w.includes("snow") || w.includes("blizzard")) return "❄";
    if (w.includes("fog") || w.includes("smog") || w.includes("haze")) return "\u{1F32B}";
    if (w.includes("overcast")) return "☁";
    if (w.includes("cloud")) return "⛅";
    if (w.includes("clear") || w.includes("sunny")) return "☀";
    if (w.includes("halloween")) return "\u{1F383}";
    return "⛅";
  }
  function weatherClass(value) {
    const w = canonical(value).toLowerCase();
    if (w.includes("thunder")) return "wx-thunder";
    if (w.includes("rain") || w.includes("clearing")) return "wx-rain";
    if (w.includes("snow") || w.includes("blizzard")) return "wx-snow";
    if (w.includes("fog") || w.includes("smog")) return "wx-fog";
    if (w.includes("overcast") || w.includes("cloud")) return "wx-cloud";
    return "wx-sun";
  }

  /* ---------------- demo snapshot (used when no feed is reachable) -------- */
  function demoSnapshot() {
    const now = Math.floor(Date.now() / 1000);
    const mk = (weather, offMin, durMin, temp) => ({
      weather, startsAt: now + offMin * 60, endsAt: now + (offMin + durMin) * 60,
      durationMin: durMin, etaMin: offMin, temp
    });
    const withAlert = SETTINGS.demoAlert === true || /[?&]alert\b/.test(location.search);
    return {
      ok: true, now,
      station: {
        name: SETTINGS.stationName, tagline: SETTINGS.tagline,
        cycleSeconds: SETTINGS.cycleSeconds, refreshSeconds: SETTINGS.refreshSeconds,
        temperatureUnit: "F"
      },
      time: { hour: 16, minute: 20, second: 0, gameMinuteOfDay: 980, isFrozen: false, scale: 30, use24Hour: false },
      weather: {
        isFrozen: false, primaryRegion: "los_santos",
        regionOrder: ["los_santos", "sandy", "paleto"],
        regions: {
          los_santos: {
            name: "Los Santos", current: "RAIN", next: "THUNDER", temp: 61,
            lowTemp: 57, highTemp: 71, temperatureUnit: "F",
            forecast: [mk("THUNDER", 5, 9, 58), mk("CLEARING", 14, 8, 62), mk("CLOUDS", 22, 12, 66), mk("CLEAR", 34, 14, 72)]
          },
          sandy: {
            name: "Sandy Shores", current: "EXTRASUNNY", next: "CLOUDS", temp: 88,
            lowTemp: 66, highTemp: 93, temperatureUnit: "F",
            forecast: [mk("CLOUDS", 8, 11, 82), mk("OVERCAST", 19, 9, 76), mk("CLEAR", 28, 15, 84)]
          },
          paleto: {
            name: "Paleto Bay", current: "FOGGY", next: "SNOWLIGHT", temp: 41,
            lowTemp: 30, highTemp: 47, temperatureUnit: "F",
            forecast: [mk("SNOWLIGHT", 6, 10, 34), mk("SNOW", 16, 12, 30), mk("OVERCAST", 28, 11, 38)]
          }
        }
      },
      disaster: withAlert ? {
        status: "running", type: "tsunami", preset: "standard",
        phase: "storm_surge", runId: "demo-run", intensity: 0.85,
        startedAt: now - 300, endsAt: now + 600,
        affectedRegions: ["los_santos", "sandy", "paleto"]
      } : null
    };
  }

  /* ---------------- feed handling ---------------------------------------- */
  const el = id => document.getElementById(id);
  const tv = el("tv");

  let snapshot = null;
  let snapshotAtMs = 0;
  let isDemo = false;
  let pushMode = false; // true once the host script pushes data itself
  let failureCount = 0;
  let regionIdx = 0;
  let cycleTimer = null;
  let cycleTimerSeconds = 0;
  let refreshTimer = null;

  function resolveDataUrl() {
    if (SETTINGS.demo) return null;
    if (SETTINGS.dataUrl) return SETTINGS.dataUrl;
    if (/^https?:$/.test(location.protocol)) {
      const p = location.pathname.replace(/\/index\.html$/i, "").replace(/\/$/, "");
      return p.endsWith("/channel") ? `${p}/data` : `${p}/channel/data`;
    }
    return null;
  }
  let dataUrl = resolveDataUrl();

  function adoptSnapshot(data, demo) {
    if (!data || data.ok !== true || !data.weather) return false;
    snapshot = data;
    snapshotAtMs = Date.now();
    isDemo = demo === true;
    el("feed-badge").hidden = !isDemo;
    if (isDemo) el("feed-badge").textContent = "DEMO FEED";
    failureCount = 0;
    scheduleCycle();
    render();
    return true;
  }

  async function refresh() {
    if (pushMode) return;
    if (!dataUrl) {
      if (!snapshot) adoptSnapshot(demoSnapshot(), true);
      return;
    }
    try {
      const res = await fetch(dataUrl, { cache: "no-store" });
      if (!res.ok) throw new Error(`http_${res.status}`);
      adoptSnapshot(await res.json(), false);
    } catch (err) {
      failureCount += 1;
      if (!snapshot && failureCount >= 2) {
        adoptSnapshot(demoSnapshot(), true);
      } else if (snapshot && !isDemo && failureCount >= 3) {
        el("feed-badge").textContent = "RECONNECTING…";
        el("feed-badge").hidden = false;
      }
    }
  }

  /* ---------------- host-script push hook ---------------------------------
     A TV resource can drive the page itself instead of letting it poll:

       SendNUIMessage({ type = 'rsweather:channel:data', data = feedJson })
       SendNUIMessage({ type = 'rsweather:channel:config',
                        dataUrl = '...', stationName = '...', tagline = '...',
                        cycleSeconds = 12, refreshSeconds = 10 })

     `data` must be the JSON object served by /rs_weather/channel/data. */
  window.addEventListener("message", event => {
    const msg = event.data;
    if (!msg || typeof msg !== "object") return;
    if (msg.type === "rsweather:channel:data" && msg.data) {
      pushMode = true;
      adoptSnapshot(msg.data, false);
    } else if (msg.type === "rsweather:channel:config") {
      for (const key of ["dataUrl", "stationName", "tagline", "cycleSeconds", "refreshSeconds"]) {
        if (msg[key] !== undefined) SETTINGS[key] = msg[key];
      }
      if (msg.dataUrl !== undefined) {
        pushMode = false;
        dataUrl = resolveDataUrl();
        refresh();
      }
      if (snapshot) render();
    }
  });

  /* ---------------- game clock ------------------------------------------- */
  function gameMinuteNow() {
    if (!snapshot) return null;
    const t = snapshot.time || {};
    let base = Number(t.gameMinuteOfDay);
    if (!Number.isFinite(base)) {
      base = (Number(t.hour) || 0) * 60 + (Number(t.minute) || 0);
    }
    if (t.isFrozen !== true) {
      const scale = Number.isFinite(Number(t.scale)) ? Number(t.scale) : 1;
      base += ((Date.now() - snapshotAtMs) / 1000) * scale / 60;
    }
    return ((base % 1440) + 1440) % 1440;
  }

  function formatClock(totalMinutes, withMinutes) {
    const t = snapshot ? snapshot.time || {} : {};
    const total = ((Math.floor(totalMinutes) % 1440) + 1440) % 1440;
    let h = Math.floor(total / 60);
    const m = String(total % 60).padStart(2, "0");
    if (t.use24Hour === true) {
      return withMinutes ? `${String(h).padStart(2, "0")}:${m}` : `${String(h).padStart(2, "0")}:00`;
    }
    const suffix = h >= 12 ? "PM" : "AM";
    h %= 12;
    if (h === 0) h = 12;
    return withMinutes ? `${h}:${m} ${suffix}` : `${h} ${suffix}`;
  }

  function tickClock() {
    const gm = gameMinuteNow();
    el("clock").textContent = gm === null ? "--:--" : formatClock(gm, true);
  }

  /* Convert a real-world epoch into an approximate in-game clock string.
     Returns null when the moment is so far ahead that the game clock would
     wrap and read out of order; callers then fall back to a real countdown. */
  function gameClockAtEpoch(epoch) {
    const gm = gameMinuteNow();
    if (gm === null || !snapshot) return null;
    const t = snapshot.time || {};
    if (t.isFrozen === true) return null;
    const scale = Number.isFinite(Number(t.scale)) ? Number(t.scale) : 1;
    const serverNow = Number(snapshot.now) + (Date.now() - snapshotAtMs) / 1000;
    const realDelta = Number(epoch) - serverNow;
    if (!Number.isFinite(realDelta)) return null;
    const gameMinutesAhead = (realDelta * scale) / 60;
    if (gameMinutesAhead > 20 * 60) return null;
    return formatClock(gm + gameMinutesAhead, false);
  }

  /* ---------------- rendering -------------------------------------------- */
  function regionOrder() {
    const order = snapshot?.weather?.regionOrder;
    if (Array.isArray(order) && order.length) {
      return order.filter(key => snapshot.weather.regions?.[key]);
    }
    return Object.keys(snapshot?.weather?.regions || {});
  }

  function fmtTemp(value) {
    const n = Number(value);
    return Number.isFinite(n) ? `${Math.round(n)}°` : "--°";
  }

  function renderRegion(key) {
    const region = snapshot.weather.regions[key];
    if (!region) return;

    el("region-name").textContent = regionLabel(key, region.name);
    el("cond-icon").textContent = weatherIcon(region.current);
    el("cond-label").textContent = weatherLabel(region.current);
    el("temp-now").textContent = fmtTemp(region.temp);
    el("hilo").innerHTML =
      `HI <b>${fmtTemp(region.highTemp)}</b><br>LO <b>${fmtTemp(region.lowTemp)}</b>`;

    const nextLine = el("next-line");
    const rows = Array.isArray(region.forecast) ? region.forecast : [];
    const first = rows[0];
    const nextWeather = region.next || (first && first.weather);
    if (nextWeather) {
      let when = "";
      if (first && Number.isFinite(Number(first.startsAt))) {
        const clock = gameClockAtEpoch(first.startsAt);
        const serverNow = Number(snapshot.now) + (Date.now() - snapshotAtMs) / 1000;
        const mins = Math.max(0, Math.round((Number(first.startsAt) - serverNow) / 60));
        when = clock ? ` around ${clock}` : ` in ${mins} min`;
      }
      nextLine.innerHTML = `UP NEXT: <b>${weatherLabel(nextWeather)}</b>${when}`;
      nextLine.hidden = false;
    } else {
      nextLine.hidden = true;
    }

    const list = el("fc-list");
    list.innerHTML = "";
    if (!rows.length) {
      const li = document.createElement("li");
      li.className = "fc-empty";
      li.textContent = "Forecast unavailable";
      list.appendChild(li);
    }
    const serverNow = Number(snapshot.now) + (Date.now() - snapshotAtMs) / 1000;
    rows.slice(0, 6).forEach(row => {
      const li = document.createElement("li");
      const clock = Number.isFinite(Number(row.startsAt)) ? gameClockAtEpoch(row.startsAt) : null;
      const mins = Number.isFinite(Number(row.startsAt))
        ? Math.max(0, Math.round((Number(row.startsAt) - serverNow) / 60))
        : null;
      const timeLabel = clock || (mins !== null ? `+${mins}m` : "—");
      li.innerHTML =
        `<span class="fc-time">${timeLabel}</span>` +
        `<span class="fc-icon">${weatherIcon(row.weather)}</span>` +
        `<span class="fc-cond">${weatherLabel(row.weather)}</span>` +
        `<span class="fc-temp">${fmtTemp(row.temp)}</span>`;
      list.appendChild(li);
    });

    tv.className = tv.classList.contains("alerting")
      ? `alerting ${weatherClass(region.current)}`
      : weatherClass(region.current);
  }

  function renderDots(order) {
    const dots = el("dots");
    dots.innerHTML = "";
    order.forEach((_, i) => {
      const dot = document.createElement("span");
      if (i === regionIdx) dot.className = "on";
      dots.appendChild(dot);
    });
  }

  function renderTicker() {
    const order = regionOrder();
    const parts = order.map(key => {
      const r = snapshot.weather.regions[key];
      let s = `${regionLabel(key, r.name).toUpperCase()} ${fmtTemp(r.temp)} ${weatherLabel(r.current).toUpperCase()}`;
      if (r.next) s += ` → ${weatherLabel(r.next).toUpperCase()}`;
      return s;
    });
    const d = snapshot.disaster;
    if (d) parts.unshift(alertText(d));
    el("ticker").textContent = parts.join("   ✦   ") + "   ✦   ";
  }

  function alertText(d) {
    const type = String(d.type || "weather").toUpperCase();
    const level = d.status === "armed" ? "WATCH" : "WARNING";
    let text = `${type} ${level}`;
    if (d.status === "running" && d.phase) {
      text += ` — ${String(d.phase).replace(/[_-]+/g, " ").toUpperCase()}`;
    } else if (d.status === "armed") {
      text += " — EVENT ARMED, STAY ALERT";
    } else if (d.status === "recovering") {
      text += " — EVENT ENDING, CONDITIONS IMPROVING";
    } else if (d.status === "paused") {
      text += " — EVENT ON HOLD";
    }
    if (Array.isArray(d.affectedRegions) && d.affectedRegions.length) {
      text += ` — ${d.affectedRegions.map(r => regionLabel(r).toUpperCase()).join(", ")}`;
    }
    return text;
  }

  function renderAlert() {
    const d = snapshot.disaster;
    const bar = el("alertbar");
    if (d) {
      el("alert-text").textContent = alertText(d);
      bar.hidden = false;
      tv.classList.add("alerting");
    } else {
      bar.hidden = true;
      tv.classList.remove("alerting");
    }
  }

  function render() {
    const station = snapshot.station || {};
    el("strap").textContent = station.tagline || SETTINGS.tagline;
    const order = regionOrder();
    if (!order.length) return;
    if (regionIdx >= order.length) regionIdx = 0;
    renderAlert();
    renderRegion(order[regionIdx]);
    renderDots(order);
    renderTicker();
    tickClock();
  }

  /* ---------------- cycling ---------------------------------------------- */
  function cycleSeconds() {
    const s = Number(snapshot?.station?.cycleSeconds);
    return Number.isFinite(s) && s >= 4 ? s : SETTINGS.cycleSeconds;
  }

  function nextRegion() {
    const order = regionOrder();
    if (order.length < 2) { render(); return; }
    const panel = el("panel");
    panel.classList.add("swapping");
    setTimeout(() => {
      regionIdx = (regionIdx + 1) % order.length;
      render();
      panel.classList.remove("swapping");
    }, 460);
  }

  function scheduleCycle() {
    const seconds = cycleSeconds();
    if (cycleTimer && cycleTimerSeconds === seconds) return;
    if (cycleTimer) clearInterval(cycleTimer);
    cycleTimerSeconds = seconds;
    cycleTimer = setInterval(nextRegion, seconds * 1000);
  }

  function scheduleRefresh() {
    if (refreshTimer) clearInterval(refreshTimer);
    const s = Number(snapshot?.station?.refreshSeconds);
    const seconds = Number.isFinite(s) && s >= 3 ? s : SETTINGS.refreshSeconds;
    refreshTimer = setInterval(refresh, seconds * 1000);
  }

  /* ---------------- boot -------------------------------------------------- */
  setInterval(tickClock, 1000);
  refresh().then(() => {
    if (!snapshot) adoptSnapshot(demoSnapshot(), true);
    scheduleRefresh();
  });
})();
