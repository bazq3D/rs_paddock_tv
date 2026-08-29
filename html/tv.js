var currentVideoId = "";

// Extract YouTube Video ID from standard YouTube URL
function getYoutubeId(url) {
    if (!url) return "";
    var regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    var match = url.match(regExp);
    return (match && match[2].length === 11) ? match[2] : url;
}

// Send postMessage command string to YouTube iframe
function sendCommand(func, args) {
    var container = document.getElementById('player-container');
    var iframe = container ? container.querySelector('iframe') : null;
    if (iframe && iframe.contentWindow) {
        try {
            var msg = JSON.stringify({
                event: 'command',
                func: func,
                args: args || []
            });
            iframe.contentWindow.postMessage(msg, '*');
        } catch (e) {}
    }
}

window.addEventListener('message', function(event) {
    var data = event.data;
    if (!data || !data.action) return;

    var container = document.getElementById('player-container');
    if (!container) return;

    if (data.action === 'play') {
        var videoId = getYoutubeId(data.url);
        if (videoId) {
            var startTime = data.time || 0;
            var vol = data.volume !== undefined ? data.volume : 30;
            
            var existingIframe = container.querySelector('iframe');
            if (currentVideoId !== videoId || !existingIframe) {
                currentVideoId = videoId;
                // Optimized embed parameters to completely strip YouTube branding, controls, and title overlays
                var embedUrl = "https://www.youtube-nocookie.com/embed/" + videoId + 
                    "?autoplay=1&mute=1&controls=0&enablejsapi=1&rel=0&showinfo=0&iv_load_policy=3" + 
                    "&modestbranding=1&disablekb=1&fs=0&playsinline=1&autohide=1&color=white&loop=1&playlist=" + videoId + 
                    "&start=" + startTime;
                
                container.innerHTML = '<iframe src="' + embedUrl + '" allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen></iframe>';

                // Unmute & set volume after playback starts
                setTimeout(function() {
                    sendCommand('unMute');
                    sendCommand('setVolume', [vol]);
                    sendCommand('playVideo');
                }, 450);
            } else {
                sendCommand('unMute');
                sendCommand('setVolume', [vol]);
                sendCommand('playVideo');
            }
        }
    } else if (data.action === 'stop') {
        currentVideoId = "";
        container.innerHTML = "";
    } else if (data.action === 'pause') {
        sendCommand('pauseVideo');
    } else if (data.action === 'resume') {
        sendCommand('unMute');
        sendCommand('playVideo');
    } else if (data.action === 'setVolume') {
        var targetVol = data.volume !== undefined ? data.volume : 30;
        sendCommand('setVolume', [targetVol]);
        if (targetVol > 0) {
            sendCommand('unMute');
        }
    } else if (data.action === 'seek') {
        sendCommand('seekTo', [data.time || 0, true]);
    }
});
