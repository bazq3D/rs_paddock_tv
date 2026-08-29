var player;
var isPlayerReady = false;
var messageQueue = [];

// YouTube API Hazır Olduğunda Çağrılır
function onYouTubeIframeAPIReady() {
    player = new YT.Player('player', {
        height: '100%',
        width: '100%',
        videoId: '',
        playerVars: {
            'autoplay': 1,
            'controls': 0,
            'disablekb': 1,
            'fs': 0,
            'rel': 0,
            'modestbranding': 1,
            'showinfo': 0,
            'iv_load_policy': 3,
            'mute': 0,
            'autohide': 1
        },
        events: {
            'onReady': onPlayerReady,
            'onStateChange': onPlayerStateChange,
            'onError': onPlayerError
        }
    });
}

function onPlayerReady(event) {
    isPlayerReady = true;
    
    // Kuyruktaki birikmiş mesajları işleme al
    while (messageQueue.length > 0) {
        var msg = messageQueue.shift();
        handleMessage(msg);
    }
}

function onPlayerStateChange(event) {
    // Video bittiğinde otomatik olarak başa dönüp tekrar oynatır (Loop)
    if (event.data === YT.PlayerState.ENDED) {
        player.playVideo();
    }
}

function onPlayerError(event) {
    console.error("YouTube Player hatası oluştu: ", event.data);
}

// YouTube URL'sinden Video ID'sini çeker
function getYoutubeId(url) {
    if (!url) return "";
    var regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    var match = url.match(regExp);
    return (match && match[2].length == 11) ? match[2] : url;
}

// Gelen mesajları yöneten fonksiyon
function handleMessage(data) {
    if (!player || typeof player.getPlayerState !== 'function') return;

    if (data.action === 'play') {
        var videoId = getYoutubeId(data.url);
        if (videoId) {
            player.loadVideoById({
                videoId: videoId,
                startSeconds: data.time || 0
            });
            player.playVideo();
        }
    } else if (data.action === 'pause') {
        player.pauseVideo();
    } else if (data.action === 'resume') {
        player.playVideo();
    } else if (data.action === 'stop') {
        player.stopVideo();
    } else if (data.action === 'setVolume') {
        player.setVolume(data.volume);
    } else if (data.action === 'seek') {
        var currentTime = player.getCurrentTime();
        if (Math.abs(currentTime - data.time) > 3) {
            player.seekTo(data.time, true);
        }
    }
}

// FiveM'den (DUI) gelen olayları yakalar
window.addEventListener('message', function(event) {
    var data = event.data;
    if (!isPlayerReady) {
        messageQueue.push(data);
    } else {
        handleMessage(data);
    }
});
