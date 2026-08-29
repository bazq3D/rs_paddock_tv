var player = null;
var isApiReady = false;
var pendingPlayData = null;
var currentVideoId = "";

// YouTube IFrame API Ready Callback
function onYouTubeIframeAPIReady() {
    isApiReady = true;
    if (pendingPlayData) {
        initPlayer(pendingPlayData.videoId, pendingPlayData.startTime, pendingPlayData.volume);
        pendingPlayData = null;
    }
}

// Extract YouTube Video ID from standard YouTube URL
function getYoutubeId(url) {
    if (!url) return "";
    var regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    var match = url.match(regExp);
    return (match && match[2].length === 11) ? match[2] : url;
}

// Initialize YouTube IFrame Player Instance
function initPlayer(videoId, startTime, volume) {
    currentVideoId = videoId;
    var vol = volume !== undefined ? volume : 30;

    if (player && typeof player.destroy === 'function') {
        try { player.destroy(); } catch (e) {}
    }

    player = new YT.Player('player', {
        videoId: videoId,
        playerVars: {
            'autoplay': 1,
            'mute': 1,
            'controls': 0,
            'showinfo': 0,
            'rel': 0,
            'modestbranding': 1,
            'disablekb': 1,
            'fs': 0,
            'iv_load_policy': 3,
            'playsinline': 1,
            'enablejsapi': 1,
            'autohide': 1,
            'start': startTime || 0,
            'loop': 1,
            'playlist': videoId
        },
        events: {
            'onReady': function(event) {
                event.target.playVideo();
                setTimeout(function() {
                    if (event.target && typeof event.target.unMute === 'function') {
                        event.target.unMute();
                        event.target.setVolume(vol);
                        event.target.playVideo();
                    }
                }, 350);
            },
            'onStateChange': function(event) {
                // If video ends or pauses unexpectedly, auto-resume playback
                if (event.data === 0) { // YT.PlayerState.ENDED
                    event.target.playVideo();
                }
            }
        }
    });
}

// FiveM DUI Event Listener
window.addEventListener('message', function(event) {
    var data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'play') {
        var videoId = getYoutubeId(data.url);
        if (!videoId) return;

        var startTime = data.time || 0;
        var vol = data.volume !== undefined ? data.volume : 30;

        if (!isApiReady) {
            pendingPlayData = { videoId: videoId, startTime: startTime, volume: vol };
            return;
        }

        if (currentVideoId !== videoId || !player) {
            initPlayer(videoId, startTime, vol);
        } else {
            if (player && typeof player.playVideo === 'function') {
                player.unMute();
                player.setVolume(vol);
                player.playVideo();
            }
        }
    } else if (data.action === 'stop') {
        currentVideoId = "";
        if (player && typeof player.stopVideo === 'function') {
            player.stopVideo();
        }
    } else if (data.action === 'pause') {
        if (player && typeof player.pauseVideo === 'function') {
            player.pauseVideo();
        }
    } else if (data.action === 'resume') {
        if (player && typeof player.playVideo === 'function') {
            player.unMute();
            player.playVideo();
        }
    } else if (data.action === 'setVolume') {
        var targetVol = data.volume !== undefined ? data.volume : 30;
        if (player && typeof player.setVolume === 'function') {
            player.setVolume(targetVol);
            if (targetVol > 0) {
                player.unMute();
            } else {
                player.mute();
            }
        }
    } else if (data.action === 'seek') {
        if (player && typeof player.seekTo === 'function') {
            player.seekTo(data.time || 0, true);
        }
    }
});
