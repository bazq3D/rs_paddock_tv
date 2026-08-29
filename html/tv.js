var currentVideoId = "";
var resourceName = "rs_paddock_tv";

// Extract resource name and initial stream URL from URL params if present
(function() {
    try {
        var params = new URLSearchParams(window.location.search);
        if (params.get('resource')) {
            resourceName = params.get('resource');
        }
    } catch(e) {}
})();

document.addEventListener("DOMContentLoaded", function() {
    try {
        var params = new URLSearchParams(window.location.search);
        var urlParam = params.get('url');
        var timeParam = params.get('time');
        var volParam = params.get('volume');

        if (urlParam) {
            var vId = youtubeVideoId(urlParam);
            if (vId) {
                currentVideoId = vId;
                var startTime = parseFloat(timeParam) || 0;
                var vol = parseInt(volParam) || 30;
                var embedUrl = youtubeEmbedUrl(urlParam, resourceName, startTime);
                showVideo(embedUrl, vol);
            }
        }
    } catch(e) {}
});

// Helper function to extract video ID from any YouTube URL format (watch, shorts, live, embed, youtu.be)
function youtubeVideoId(url) {
    var value = String(url || "").trim();
    if (!value) return "";
    try {
        var parsed = new URL(value);
        var host = parsed.hostname.replace(/^www\./i, "").toLowerCase();
        if (host === "youtu.be") return parsed.pathname.split("/").filter(Boolean)[0] || "";
        if (host === "youtube.com" || host === "m.youtube.com" || host === "youtube-nocookie.com") {
            var direct = parsed.searchParams.get("v");
            if (direct) return direct;
            var parts = parsed.pathname.split("/").filter(Boolean);
            if (parts[0] === "embed" || parts[0] === "shorts" || parts[0] === "live") return parts[1] || "";
        }
    } catch (e) {}
    var m = value.match(/(?:youtu\.be\/|youtube(?:-nocookie)?\.com\/(?:watch\?v=|embed\/|shorts\/|live\/))([A-Za-z0-9_-]{6,})/i);
    return m ? m[1] : "";
}

// Build clean chromeless YouTube embed URL with NUI origin
function youtubeEmbedUrl(url, resName, startTime) {
    var id = youtubeVideoId(url);
    if (!id) return "";
    var origin = "https://cfx-nui-" + resName;
    var params = new URLSearchParams({
        autoplay: "1",
        mute: "0",
        controls: "0",
        loop: "1",
        playlist: id,
        playsinline: "1",
        modestbranding: "1",
        rel: "0",
        iv_load_policy: "3",
        disablekb: "1",
        enablejsapi: "1"
    });
    if (startTime && startTime > 0) {
        params.set("start", Math.floor(startTime));
    }
    return "https://www.youtube.com/embed/" + encodeURIComponent(id) + "?" + params.toString();
}

// Send postMessage command to YouTube iframe player
function sendCommand(func, args) {
    var iframe = document.getElementById("yt");
    if (iframe && iframe.contentWindow) {
        try {
            iframe.contentWindow.postMessage(JSON.stringify({
                event: "command",
                func: func,
                args: args || []
            }), "*");
        } catch (e) {}
    }
}

// Show video iframe and fade out black mask overlay
function showVideo(embedUrl, volume) {
    var iframe = document.getElementById("yt");
    var overlay = document.getElementById("black-overlay");
    if (!iframe) return;

    if (overlay) overlay.style.opacity = "1";
    iframe.src = embedUrl;

    var vol = volume !== undefined ? volume : 30;

    // Periodically send unMute and setVolume commands to guarantee playback unmutes
    [400, 900, 1400, 2200].forEach(function(delay) {
        setTimeout(function() {
            sendCommand("unMute");
            sendCommand("setVolume", [vol]);
            sendCommand("playVideo");
            if (overlay && delay >= 1400) overlay.style.opacity = "0";
        }, delay);
    });
}

// NUI DUI Event Listener
window.addEventListener("message", function(event) {
    var data = event.data;
    if (!data || !data.action) return;

    if (data.action === "play") {
        var vId = youtubeVideoId(data.url);
        if (!vId) return;

        var vol = data.volume !== undefined ? data.volume : 30;

        if (currentVideoId !== vId) {
            currentVideoId = vId;
            var embedUrl = youtubeEmbedUrl(data.url, resourceName, data.time);
            showVideo(embedUrl, vol);
        } else {
            sendCommand("unMute");
            sendCommand("setVolume", [vol]);
            sendCommand("playVideo");
        }
    } else if (data.action === "stop") {
        currentVideoId = "";
        var iframe = document.getElementById("yt");
        if (iframe) iframe.src = "about:blank";
        var overlay = document.getElementById("black-overlay");
        if (overlay) overlay.style.opacity = "1";
    } else if (data.action === "pause") {
        sendCommand("pauseVideo");
    } else if (data.action === "resume") {
        sendCommand("unMute");
        sendCommand("playVideo");
    } else if (data.action === "setVolume") {
        var targetVol = data.volume !== undefined ? data.volume : 30;
        sendCommand("setVolume", [targetVol]);
        if (targetVol > 0) {
            sendCommand("unMute");
        } else {
            sendCommand("mute");
        }
    } else if (data.action === "seek") {
        sendCommand("seekTo", [data.time || 0, true]);
    }
});
